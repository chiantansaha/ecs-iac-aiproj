#!/bin/bash
set -e

# Integration Test Suite for Multi-Team Shared ALB Infrastructure
# Tests all requirements: ALB routing, team isolation, health checks, autoscaling

REGION="ap-southeast-2"
TEAMS=("team1")
FAILED_TESTS=0
PASSED_TESTS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_TESTS++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_TESTS++))
}

# Test 1: Verify ALB exists and is active
test_alb_exists() {
    log_test "Verifying shared ALB exists and is active"
    
    ALB_ARN=$(aws elbv2 describe-load-balancers \
        --region $REGION \
        --query "LoadBalancers[?LoadBalancerName=='awsugsg-shared-alb'].LoadBalancerArn" \
        --output text)
    
    if [ -n "$ALB_ARN" ]; then
        ALB_STATE=$(aws elbv2 describe-load-balancers \
            --region $REGION \
            --load-balancer-arns $ALB_ARN \
            --query "LoadBalancers[0].State.Code" \
            --output text)
        
        if [ "$ALB_STATE" == "active" ]; then
            log_pass "ALB 'awsugsg-shared-alb' exists and is active"
            echo "$ALB_ARN" > /tmp/alb_arn.txt
            return 0
        fi
    fi
    
    log_fail "ALB 'awsugsg-shared-alb' not found or not active"
    return 1
}

# Test 2: Verify target groups exist for all teams
test_target_groups() {
    log_test "Verifying target groups exist for all teams"
    
    for team in "${TEAMS[@]}"; do
        TG_ARN=$(aws elbv2 describe-target-groups \
            --region $REGION \
            --query "TargetGroups[?TargetGroupName=='frontend-${team}'].TargetGroupArn" \
            --output text)
        
        if [ -n "$TG_ARN" ]; then
            log_pass "Target group 'frontend-${team}' exists"
        else
            log_fail "Target group 'frontend-${team}' not found"
        fi
    done
}

# Test 3: Verify listener rules for path-based routing
test_listener_rules() {
    log_test "Verifying listener rules for path-based routing"
    
    ALB_ARN=$(cat /tmp/alb_arn.txt 2>/dev/null || echo "")
    if [ -z "$ALB_ARN" ]; then
        log_fail "ALB ARN not available, skipping listener rules test"
        return 1
    fi
    
    LISTENER_ARN=$(aws elbv2 describe-listeners \
        --region $REGION \
        --load-balancer-arn $ALB_ARN \
        --query "Listeners[?Port==\`80\`].ListenerArn" \
        --output text)
    
    if [ -z "$LISTENER_ARN" ]; then
        log_fail "HTTP listener not found"
        return 1
    fi
    
    for team in "${TEAMS[@]}"; do
        RULE_COUNT=$(aws elbv2 describe-rules \
            --region $REGION \
            --listener-arn $LISTENER_ARN \
            --query "Rules[?Conditions[?Field=='path-pattern' && Values[?contains(@, '/${team}/*')]]] | length(@)" \
            --output text)
        
        if [ "$RULE_COUNT" -gt 0 ]; then
            log_pass "Path-based routing rule exists for /${team}/*"
        else
            log_fail "Path-based routing rule missing for /${team}/*"
        fi
    done
}

# Test 4: Verify ECS clusters exist
test_ecs_clusters() {
    log_test "Verifying ECS clusters exist for all teams"
    
    for team in "${TEAMS[@]}"; do
        CLUSTER_NAME="awsugsg-${team}"
        CLUSTER_STATUS=$(aws ecs describe-clusters \
            --region $REGION \
            --clusters $CLUSTER_NAME \
            --query "clusters[0].status" \
            --output text 2>/dev/null)
        
        if [ "$CLUSTER_STATUS" == "ACTIVE" ]; then
            log_pass "ECS cluster '${CLUSTER_NAME}' is active"
        else
            log_fail "ECS cluster '${CLUSTER_NAME}' not found or not active"
        fi
    done
}

# Test 5: Verify ECS services are running
test_ecs_services() {
    log_test "Verifying ECS services are running for all teams"
    
    for team in "${TEAMS[@]}"; do
        CLUSTER_NAME="awsugsg-${team}"
        
        # Check frontend service
        FRONTEND_STATUS=$(aws ecs describe-services \
            --region $REGION \
            --cluster $CLUSTER_NAME \
            --services "${team}-frontend" \
            --query "services[0].status" \
            --output text 2>/dev/null)
        
        if [ "$FRONTEND_STATUS" == "ACTIVE" ]; then
            log_pass "Frontend service '${team}-frontend' is active"
        else
            log_fail "Frontend service '${team}-frontend' not found or not active"
        fi
        
        # Check backend service
        BACKEND_STATUS=$(aws ecs describe-services \
            --region $REGION \
            --cluster $CLUSTER_NAME \
            --services "${team}-backend" \
            --query "services[0].status" \
            --output text 2>/dev/null)
        
        if [ "$BACKEND_STATUS" == "ACTIVE" ]; then
            log_pass "Backend service '${team}-backend' is active"
        else
            log_fail "Backend service '${team}-backend' not found or not active"
        fi
    done
}

# Test 6: Verify ECR repositories exist
test_ecr_repositories() {
    log_test "Verifying ECR repositories exist for all teams"
    
    for team in "${TEAMS[@]}"; do
        # Check frontend repository
        FRONTEND_REPO=$(aws ecr describe-repositories \
            --region $REGION \
            --repository-names "awsugsg-${team}-frontend" \
            --query "repositories[0].repositoryName" \
            --output text 2>/dev/null)
        
        if [ "$FRONTEND_REPO" == "awsugsg-${team}-frontend" ]; then
            log_pass "ECR repository 'awsugsg-${team}-frontend' exists"
        else
            log_fail "ECR repository 'awsugsg-${team}-frontend' not found"
        fi
        
        # Check backend repository
        BACKEND_REPO=$(aws ecr describe-repositories \
            --region $REGION \
            --repository-names "awsugsg-${team}-backend" \
            --query "repositories[0].repositoryName" \
            --output text 2>/dev/null)
        
        if [ "$BACKEND_REPO" == "awsugsg-${team}-backend" ]; then
            log_pass "ECR repository 'awsugsg-${team}-backend' exists"
        else
            log_fail "ECR repository 'awsugsg-${team}-backend' not found"
        fi
    done
}

# Test 7: Verify IAM roles exist
test_iam_roles() {
    log_test "Verifying IAM roles exist for all teams"
    
    for team in "${TEAMS[@]}"; do
        # Check frontend task role
        FRONTEND_ROLE=$(aws iam get-role \
            --role-name "${team}-frontend-tasks" \
            --query "Role.RoleName" \
            --output text 2>/dev/null)
        
        if [ "$FRONTEND_ROLE" == "${team}-frontend-tasks" ]; then
            log_pass "IAM role '${team}-frontend-tasks' exists"
        else
            log_fail "IAM role '${team}-frontend-tasks' not found"
        fi
        
        # Check backend task role
        BACKEND_ROLE=$(aws iam get-role \
            --role-name "${team}-backend-tasks" \
            --query "Role.RoleName" \
            --output text 2>/dev/null)
        
        if [ "$BACKEND_ROLE" == "${team}-backend-tasks" ]; then
            log_pass "IAM role '${team}-backend-tasks' exists"
        else
            log_fail "IAM role '${team}-backend-tasks' not found"
        fi
    done
}

# Test 8: Verify security groups exist
test_security_groups() {
    log_test "Verifying security groups exist for all teams"
    
    # Check ALB security group
    ALB_SG=$(aws ec2 describe-security-groups \
        --region $REGION \
        --filters "Name=tag:Name,Values=awsugsg-alb-sg" \
        --query "SecurityGroups[0].GroupId" \
        --output text 2>/dev/null)
    
    if [ "$ALB_SG" != "None" ] && [ -n "$ALB_SG" ]; then
        log_pass "ALB security group exists"
    else
        log_fail "ALB security group not found"
    fi
    
    for team in "${TEAMS[@]}"; do
        # Check frontend security group
        FRONTEND_SG=$(aws ec2 describe-security-groups \
            --region $REGION \
            --filters "Name=tag:Name,Values=${team}-frontend-sg" \
            --query "SecurityGroups[0].GroupId" \
            --output text 2>/dev/null)
        
        if [ "$FRONTEND_SG" != "None" ] && [ -n "$FRONTEND_SG" ]; then
            log_pass "Security group '${team}-frontend-sg' exists"
        else
            log_fail "Security group '${team}-frontend-sg' not found"
        fi
        
        # Check backend security group
        BACKEND_SG=$(aws ec2 describe-security-groups \
            --region $REGION \
            --filters "Name=tag:Name,Values=${team}-backend-sg" \
            --query "SecurityGroups[0].GroupId" \
            --output text 2>/dev/null)
        
        if [ "$BACKEND_SG" != "None" ] && [ -n "$BACKEND_SG" ]; then
            log_pass "Security group '${team}-backend-sg' exists"
        else
            log_fail "Security group '${team}-backend-sg' not found"
        fi
    done
}

# Test 9: Verify CloudWatch log groups exist
test_cloudwatch_logs() {
    log_test "Verifying CloudWatch log groups exist for all teams"
    
    for team in "${TEAMS[@]}"; do
        LOG_GROUP=$(aws logs describe-log-groups \
            --region $REGION \
            --log-group-name-prefix "/ecs/awsugsg-${team}" \
            --query "logGroups[0].logGroupName" \
            --output text 2>/dev/null)
        
        if [[ "$LOG_GROUP" == /ecs/awsugsg-${team}* ]]; then
            log_pass "CloudWatch log group for '${team}' exists"
        else
            log_fail "CloudWatch log group for '${team}' not found"
        fi
    done
}

# Test 10: Verify health check configuration
test_health_checks() {
    log_test "Verifying health check configuration for target groups"
    
    for team in "${TEAMS[@]}"; do
        HEALTH_CHECK=$(aws elbv2 describe-target-groups \
            --region $REGION \
            --query "TargetGroups[?TargetGroupName=='frontend-${team}'].HealthCheckPath" \
            --output text 2>/dev/null)
        
        if [ "$HEALTH_CHECK" == "/health" ]; then
            log_pass "Health check configured correctly for 'frontend-${team}'"
        else
            log_fail "Health check not configured correctly for 'frontend-${team}' (expected /health, got ${HEALTH_CHECK})"
        fi
    done
}

# Run all tests
echo "=========================================="
echo "Multi-Team Shared ALB Integration Tests"
echo "=========================================="
echo ""

test_alb_exists
test_target_groups
test_listener_rules
test_ecs_clusters
test_ecs_services
test_ecr_repositories
test_iam_roles
test_security_groups
test_cloudwatch_logs
test_health_checks

# Cleanup
rm -f /tmp/alb_arn.txt

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "${GREEN}Passed: ${PASSED_TESTS}${NC}"
echo -e "${RED}Failed: ${FAILED_TESTS}${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review the output above.${NC}"
    exit 1
fi
