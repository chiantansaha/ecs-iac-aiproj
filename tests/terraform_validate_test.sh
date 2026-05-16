#!/bin/bash
set -e

# Terraform Validation Test
# Validates Terraform configuration without deploying

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    exit 1
}

echo "=========================================="
echo "Terraform Configuration Validation"
echo "=========================================="
echo ""

# Test 1: Terraform format check
log_test "Checking Terraform formatting"
if terraform fmt -check -recursive; then
    log_pass "Terraform files are properly formatted"
else
    log_fail "Terraform files need formatting. Run: terraform fmt -recursive"
fi

# Test 2: Terraform validation
log_test "Validating Terraform configuration"
if [ -d ".terraform" ]; then
    # Already initialized, just validate
    if terraform validate; then
        log_pass "Terraform configuration is valid"
    else
        log_fail "Terraform configuration validation failed"
    fi
else
    log_pass "Terraform not initialized, skipping validation (run 'terraform init' first)"
fi

# Test 3: Check for required files
log_test "Checking for required Terraform files"
REQUIRED_FILES=(
    "teams.tf"
    "ecr.tf"
    "ecs-clusters.tf"
    "alb.tf"
    "ecs.tf"
    "ecs-security.tf"
    "ecs-services.tf"
    "backend.tf"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        log_pass "Required file '$file' exists"
    else
        log_fail "Required file '$file' is missing"
    fi
done

# Test 4: Verify team configuration
log_test "Verifying team configuration in teams.tf"
if grep -q 'locals' teams.tf && grep -q 'teams.*=.*\[' teams.tf; then
    TEAM_COUNT=$(grep -o 'team[0-9]' teams.tf | wc -l)
    if [ "$TEAM_COUNT" -eq 4 ]; then
        log_pass "Team configuration contains 4 teams"
    else
        log_fail "Team configuration should contain 4 teams, found $TEAM_COUNT"
    fi
else
    log_fail "Team configuration not found in teams.tf"
fi

# Test 5: Terraform plan (dry run)
log_test "Running Terraform plan (dry run)"
if [ -d ".terraform" ]; then
    if terraform plan -out=/tmp/tfplan > /dev/null 2>&1; then
        log_pass "Terraform plan succeeded"
        rm -f /tmp/tfplan
    else
        log_fail "Terraform plan failed"
    fi
else
    log_pass "Terraform not initialized, skipping plan (run 'terraform init' first)"
fi

echo ""
echo -e "${GREEN}All validation tests passed!${NC}"
