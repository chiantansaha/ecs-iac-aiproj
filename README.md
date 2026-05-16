# Infrastructure as Code (IaC)

Terraform configuration for deploying a multi-team awsugsg AI chatbot platform on AWS ECS with shared Application Load Balancer.

## Architecture

### Visual Overview
For a comprehensive visual representation of the infrastructure, see the [AWS Architecture Diagram](../.kiro/specs/aws-architecture-diagram/aws-architecture-diagram.drawio).

![Architecture Diagram](../.kiro/specs/aws-architecture-diagram/aws-architecture-diagram.drawio)

*Open the [draw.io file](../.kiro/specs/aws-architecture-diagram/aws-architecture-diagram.drawio) in [draw.io](https://app.diagrams.net/) for interactive viewing.*

### Infrastructure Components

- **Multi-Team Support**: you can have isolated teams (team1) with dedicated resources
- **Shared ALB**: Single internal Application Load Balancer with path-based routing (`/team1/`)
- **ECS Fargate**: Separate clusters for each team running frontend and backend services
- **ECR**: Team-specific container image repositories (8 total: frontend + backend per team)
- **S3**: Document storage and Terraform state
- **IAM**: Team-isolated roles with Bedrock permissions
- **Security**: Network isolation between teams via security groups
- **AgentCore Integration**: Optional VPC mode support with custom agents and memory configuration

## Cost Optimizations

- **ALB Minimum Capacity**: 10 capacity units for maximum cost reduction (60% savings vs default)
- **Fargate Spot**: 100% Spot instances for ~70% cost savings
- **Task Sizing**: Minimal 256 CPU / 512 MB memory per task
- **Health Check Interval**: 30 seconds to reduce health check costs by 50%
- **Log Retention**: 1 day for minimal storage costs
- **Auto-scaling**: Scale from 1-3 instances per service

## Quick Start

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Deploy infrastructure for all teams
terraform apply
```

## Configuration

Copy and customize the example variables:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Key variables:
- `vpc_id`: Existing VPC ID
- `container_port`: Application port (default: 8080)
- `desired_count`: Number of service instances per team
- `allowed_ips`: IP addresses allowed to access the ALB
- `enable_agentcore_vpc_mode`: Enable VPC mode for AgentCore agents (default: true)
- `agentcore_agents`: Custom AgentCore agents configuration (optional)
- `agentcore_memory_config`: Custom AgentCore memory configuration (optional)
- `create_self_signed_cert`: Create self-signed certificate for development (default: false)
- `acm_certificate_arn`: ARN of ACM certificate for HTTPS listener
- `log_retention_days`: CloudWatch log retention in days (default: 1)

## Team Access

After deployment, teams can access their applications via the internal ALB:
- **Team 1**: `http://<internal-alb-dns-name>/team1/`

Note: The ALB is internal and only accessible from within the VPC or through allowed IP addresses.

## Team Port Configuration

Each team uses dedicated ports to avoid conflicts:

| Team | Frontend Port | Backend Port |
|------|---------------|--------------|
| team1 | 8081 | 9081 |


## Resource Naming

| Resource Type | Pattern | Example |
|--------------|---------|---------|
| ECS Cluster | `awsugsg-{team}` | `awsugsg-team1` |
| Frontend Service | `{team}-frontend` | `team1-frontend` |
| Backend Service | `{team}-backend` | `team1-backend` |
| ECR Repository | `awsugsg-{team}-{type}` | `awsugsg-team1-frontend` |
| IAM Role | `{team}-{type}-tasks` | `team1-frontend-tasks` |

## Tagging Strategy

**Team-specific resources**:
- `app = "awsugsg-team1"` (for team1 resources)

**Shared resources**:
- `app = "awsugsg"` (for ALB and shared infrastructure)

## Permissions

Each team's ECS tasks have isolated permissions:

**Frontend Services:**
- **Bedrock AgentCore**: Runtime invocation
- **SSM**: Parameter store access

**Backend Services:**
- **Bedrock AgentCore**: Runtime invocation  
- **Bedrock Models**: Direct model access (`InvokeModel`, `InvokeModelWithResponseStream`)
- **SSM**: Parameter store access

## Network Security

- **Frontend**: Accessible from ALB only, can communicate with same-team backend
- **Backend**: Accessible from same-team frontend only, isolated from other teams
- **Cross-team isolation**: team1 frontend cannot access team2 backend

## Outputs

After deployment, key outputs include:
- `alb_dns_name`: Shared load balancer DNS name
- `frontend_ecr_repository_urls`: All frontend container registries
- `backend_ecr_repository_urls`: All backend container registries
- `ecs_cluster_names`: All ECS cluster names
- `team_url_paths`: URL paths for each team

## State Management

Terraform state is stored in S3:
- **Bucket**: `terraform-state-awsugsg-739907928373`
- **Key**: `awsugsg/terraform.tfstate`
- **Region**: `ap-southeast-2`

## Scaling

Each team's services can autoscale independently:
- **Min capacity**: 1 instance
- **Max capacity**: 3 instances
- **Capacity provider**: Fargate Spot for cost optimization
- **Scaling metrics**: CPU and memory utilization (75% target)

## Module Versions

- **ALB Module**: v10.0.2 (latest with HTTP/2 and cross-zone load balancing)
- **ECS Module**: v6.7.0 (enhanced container lifecycle management)
- **AWS Provider**: v6.18+ (required for latest features)
- **Terraform**: v1.13.0+ (required minimum version)

## Performance Features

- **Init Process**: Enabled for better container signal handling
- **HTTP/2**: Enabled on ALB for improved performance
- **Cross-Zone Load Balancing**: Explicitly enabled for improved traffic distribution
- **Optimized Health Checks**: Faster recovery with reduced overhead
- **Desync Mitigation**: Defensive mode for enhanced security
- **Invalid Header Filtering**: Enabled for better security

## Cost Monitoring

Track costs using AWS Cost Explorer with these tags:
- `Project = "awsugsg"`
- `Team = "team1"`
- `app = "awsugsg-team1"`
- `Environment = "dev"`

## Troubleshooting

**Common Issues:**
1. **ALB 503 errors**: Check target group health and security group rules
2. **ECS service not starting**: Verify ECR image exists and IAM permissions
3. **Cross-team access**: Ensure security groups block inter-team communication
4. **High costs**: Verify Fargate Spot is enabled and autoscaling is working

**Useful Commands:**
```bash
# Check ALB target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# View ECS service events
aws ecs describe-services --cluster <cluster-name> --services <service-name>

# Check container logs
aws logs get-log-events --log-group-name "/ecs/awsugsg-team1" --log-stream-name <stream-name>
```
