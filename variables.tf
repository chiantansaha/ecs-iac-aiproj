# Variables file 

variable "name" {
  description = "The name of this template (e.g., my-app-prod)"
  type        = string
  default     = ""
}

variable "region" {
  description = "The AWS region to deploy to (e.g., ap-southeast-2)"
  type        = string
  default     = "ap-southeast-2"
}

variable "container_name" {
  description = "The name of the container"
  type        = string
  default     = "app"
}

variable "container_port" {
  description = "The port that the container is listening on"
  type        = number
  default     = 8080
}

variable "health_check" {
  description = "A map containing configuration for the health check"
  type        = string
  default     = "/_stcore/health"
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "image" {
  description = "container image to initially bootstrap. future images can be deployed using a separate mechanism"
  type        = string
  default     = "public.ecr.aws/jritsema/defaultbackend"
}

variable "orchestrator_agent_arn" {
  description = "ARN of the AgentCore Orchestrator Agent"
  type        = string
  default     = ""
}

variable "agentcore_memory_id" {
  description = "AgentCore memory id (optional)"
  type        = string
  default     = ""
}

variable "allowed_ips" {
  description = "List of IP addresses/CIDR blocks allowed to access the web interface"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS listener"
  type        = string
  default     = ""
}

variable "create_self_signed_cert" {
  description = "Whether to create a self-signed certificate for internal ALB (development only)"
  type        = bool
  default     = false
}

variable "alb_access_logs_enabled" {
  description = "Enable ALB access logs"
  type        = bool
  default     = false
}

variable "alb_connection_logs_enabled" {
  description = "Enable ALB connection logs"
  type        = bool
  default     = false
}



variable "log_retention_days" {
  description = "CloudWatch log retention in days for cost optimization"
  type        = number
  default     = 1
}

variable "desired_count" {
  description = "Desired number of ECS service instances"
  type        = number
  default     = 1
}

variable "vpc_id" {
  description = "ID of existing VPC to use"
  type        = string
}

variable "enable_agentcore_vpc_mode" {
  description = "Enable VPC mode for AgentCore agents"
  type        = bool
  default     = true
}

variable "agentcore_agents" {
  description = "Custom AgentCore agents configuration (optional - uses module defaults if not provided)"
  type = map(object({
    name        = string
    description = string
    entrypoint  = string
    role_name   = optional(string)
  }))
  default = null
}

variable "agentcore_memory_config" {
  description = "Custom AgentCore memory configuration (optional - uses module defaults if not provided)"
  type = object({
    name              = string
    description       = string
    event_expiry_days = number
    strategies = list(object({
      type        = string
      name        = string
      description = string
      namespaces  = list(string)
    }))
  })
  default = null
}
# Lambda MCP Server Configuration Variables

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
  default     = "aws-assistant"
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "development"
}

variable "aws_region" {
  description = "AWS region for Lambda deployment"
  type        = string
  default     = "us-east-1"
}

variable "service_version" {
  description = "Version of the service"
  type        = string
  default     = "1.0.0"
}

variable "log_level" {
  description = "Log level for Lambda functions"
  type        = string
  default     = "INFO"
  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARNING, ERROR, CRITICAL."
  }
}

variable "enable_xray_tracing" {
  description = "Enable AWS X-Ray tracing"
  type        = bool
  default     = true
}

variable "cloudwatch_alarm_actions" {
  description = "List of ARNs for CloudWatch alarm actions (e.g., SNS topics)"
  type        = list(string)
  default     = []
}

variable "llm_logs_bucket_name" {
  description = "Name of an existing S3 bucket used for LLM logs. Leave empty to skip external LLM logs bucket usage."
  type        = string
  default     = ""
}

variable "my_team1_s3_bucket_name" {
  description = "Name of the existing S3 bucket for team1 documents."
  type        = string
  default     = ""
}

# IAM MCP Server Configuration

variable "iam_max_policy_size" {
  description = "Maximum policy size for IAM operations in bytes"
  type        = number
  default     = 10240
}

variable "iam_max_results_per_query" {
  description = "Maximum results per IAM query"
  type        = number
  default     = 100
}

variable "iam_enable_policy_simulation" {
  description = "Enable IAM policy simulation functionality"
  type        = bool
  default     = true
}

variable "iam_cache_ttl_seconds" {
  description = "Cache TTL for IAM operations in seconds"
  type        = number
  default     = 300
}

# CloudTrail MCP Server Configuration

variable "cloudtrail_max_events_per_query" {
  description = "Maximum events per CloudTrail query"
  type        = number
  default     = 50
}

variable "cloudtrail_default_time_range_hours" {
  description = "Default time range for CloudTrail queries in hours"
  type        = number
  default     = 24
}

variable "cloudtrail_max_time_range_days" {
  description = "Maximum time range for CloudTrail queries in days"
  type        = number
  default     = 90
}

variable "cloudtrail_enable_event_filtering" {
  description = "Enable event filtering for CloudTrail queries"
  type        = bool
  default     = true
}

variable "cloudtrail_cache_ttl_seconds" {
  description = "Cache TTL for CloudTrail operations in seconds"
  type        = number
  default     = 600
}

# AgentCore Gateway Configuration
variable "agentcore_gateway_url" {
  description = "URL for AgentCore Gateway endpoint"
  type        = string
  default     = ""
}

variable "enable_agentcore_integration" {
  description = "Enable AgentCore Gateway integration for Lambda functions"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "enable_cloudwatch_dashboard" {
  description = "Enable CloudWatch dashboard for monitoring"
  type        = bool
  default     = true
}

variable "enable_custom_metrics" {
  description = "Enable custom CloudWatch metrics and log filters"
  type        = bool
  default     = true
}

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods for CloudWatch alarms"
  type        = number
  default     = 2
}

variable "cpu_utilization_threshold" {
  description = "CPU utilization threshold for ECS service alarms"
  type        = number
  default     = 80
}

variable "memory_utilization_threshold" {
  description = "Memory utilization threshold for ECS service alarms"
  type        = number
  default     = 85
}

variable "alb_minimum_capacity_units" {
  description = "Minimum ALB capacity units for cost optimization (100 = minimum allowed)"
  type        = number
  default     = 100
}

variable "ecs_runtime_platform" {
  description = "ECS runtime platform architecture (X86_64 or ARM64)"
  type        = string
  default     = "X86_64"
  validation {
    condition     = contains(["X86_64", "ARM64"], var.ecs_runtime_platform)
    error_message = "ECS runtime platform must be X86_64 or ARM64."
  }
}

variable "enable_ecs_dual_stack_ipv6" {
  description = "Enable dual-stack IPv6 for ECS tasks"
  type        = bool
  default     = false
}

variable "enable_alb_waf_fail_open" {
  description = "Enable WAF fail open mode for ALB"
  type        = bool
  default     = false
}

variable "alb_idle_timeout" {
  description = "ALB idle timeout in seconds"
  type        = number
  default     = 60
}

variable "enable_ecs_container_insights" {
  description = "Enable Container Insights for ECS clusters"
  type        = bool
  default     = true
}

variable "ecs_availability_zone_rebalancing" {
  description = "Enable availability zone rebalancing for ECS services"
  type        = string
  default     = "ENABLED"
  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.ecs_availability_zone_rebalancing)
    error_message = "Must be ENABLED or DISABLED."
  }
}