# Multi-Team Shared ALB Integration Tests

This directory contains integration and validation tests for the multi-team awsugsg infrastructure.

## Test Suite Overview

### 1. Terraform Validation Test (`terraform_validate_test.sh`)

Validates Terraform configuration without deploying infrastructure.

**Tests:**
- Terraform formatting compliance
- Configuration validation
- Required files existence
- Team configuration correctness
- Terraform plan execution

**Usage:**
```bash
cd 
./tests/terraform_validate_test.sh
```

**Requirements:**
- Terraform installed
- Valid AWS credentials configured

---

### 2. Integration Test (`integration_test.sh`)

Validates deployed infrastructure against all requirements.

**Tests:**
- ALB existence and active state
- Target groups for all teams
- Path-based routing rules (`/team1/*`)
- ECS clusters (4 clusters: `awsugsg-team1`)
- ECS services (8 services: frontend + backend per team)
- ECR repositories (8 repositories)
- IAM roles (8 roles: frontend + backend per team)
- Security groups (ALB + 8 team-specific groups)
- CloudWatch log groups
- Health check configuration

**Usage:**
```bash
cd ~/ecs-iac-aiproj
./tests/integration_test.sh
```

**Requirements:**
- AWS CLI installed and configured
- Infrastructure deployed to AWS
- Appropriate IAM permissions to describe resources

---

## Running All Tests

### Pre-Deployment Validation
```bash
# Validate Terraform configuration before deployment
./tests/terraform_validate_test.sh
```

### Post-Deployment Integration Testing
```bash
# After deploying infrastructure, run integration tests
./tests/integration_test.sh
```

---

## Test Coverage

The test suite validates all requirements from the specification:

| Requirement | Test Coverage |
|------------|---------------|
| 1.1 - ECS Clusters | `test_ecs_clusters()` |
| 2.1 - ECR Repositories | `test_ecr_repositories()` |
| 3.1-3.7 - ALB & Routing | `test_alb_exists()`, `test_listener_rules()` |
| 4.1-4.6 - ECS Services | `test_ecs_services()`, `test_cloudwatch_logs()` |
| 5.1-5.6 - Security Groups | `test_security_groups()` |
| 6.1-6.4 - Health Checks | `test_health_checks()` |
| 7.1-7.5 - IAM Roles | `test_iam_roles()` |
| 8.1-8.3 - State Management | Manual verification |
| 9.1-9.4 - Multi-Team Config | `terraform_validate_test.sh` |
| 10.1-10.3 - Service Discovery | Requires deployed services |

---

## Continuous Integration

These tests can be integrated into CI/CD pipelines:

```yaml
# Example GitLab CI configuration
test:
  stage: test
  script:
    - cd iac
    - ./tests/terraform_validate_test.sh
    
integration:
  stage: integration
  script:
    - cd iac
    - ./tests/integration_test.sh
  only:
    - main
```

---

## Troubleshooting

### Test Failures

**Terraform Validation Fails:**
- Run `terraform fmt -recursive` to fix formatting
- Check for syntax errors in `.tf` files
- Ensure all required variables are defined

**Integration Test Fails:**
- Verify infrastructure is deployed: `terraform state list`
- Check AWS credentials: `aws sts get-caller-identity`
- Ensure correct region is configured (ap-southeast-2)
- Review CloudWatch logs for service errors

### Common Issues

1. **"ALB not found"**: Infrastructure may not be deployed or ALB name is incorrect
2. **"Service not active"**: ECS services may be starting up, wait 2-3 minutes
3. **"Permission denied"**: Ensure IAM user has read permissions for all tested resources
