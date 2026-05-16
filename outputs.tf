output "teams" {
  description = "List of teams deployed"
  value       = local.teams
}

output "name" {
  description = "The name of the application"
  value       = var.name
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = local.vpc_id
}

output "ecs_cluster_names" {
  description = "The names of the ECS clusters that were created"
  value       = { for team in local.teams : team => module.ecs_cluster[team].name }
}

output "ecs_cluster_arns" {
  description = "The ARNs of the ECS clusters that were created"
  value       = { for team in local.teams : team => module.ecs_cluster[team].arn }
}

output "frontend_service_names" {
  description = "The names of the frontend services"
  value       = { for team in local.teams : team => length(local.private_subnet_ids) > 0 ? module.frontend_service[team].name : "not_created" }
}

output "frontend_service_ids" {
  description = "The IDs of the frontend services"
  value       = { for team in local.teams : team => length(local.private_subnet_ids) > 0 ? module.frontend_service[team].id : "not_created" }
}

output "backend_service_names" {
  description = "The names of the backend services"
  value       = { for team in local.teams : team => length(local.private_subnet_ids) > 0 ? module.backend_service[team].name : "not_created" }
}

output "backend_service_ids" {
  description = "The IDs of the backend services"
  value       = { for team in local.teams : team => length(local.private_subnet_ids) > 0 ? module.backend_service[team].id : "not_created" }
}

output "frontend_ecr_repository_urls" {
  description = "The URLs of the frontend ECR repositories"
  value       = { for team in local.teams : team => aws_ecr_repository.frontend[team].repository_url }
}

output "backend_ecr_repository_urls" {
  description = "The URLs of the backend ECR repositories"
  value       = { for team in local.teams : team => aws_ecr_repository.backend[team].repository_url }
}

output "lb_arn" {
  description = "The ARN of the shared load balancer"
  value       = module.alb.arn
}

output "alb_dns_name" {
  description = "The shared load balancer DNS name"
  value       = module.alb.dns_name
}

output "team_url_paths" {
  description = "The URL paths for each team"
  value       = { for team in local.teams : team => "/${team}/" }
}

output "service_discovery_namespaces" {
  description = "Service discovery namespace IDs for each team"
  value       = { for team in local.teams : team => aws_service_discovery_private_dns_namespace.team_namespace[team].id }
}

output "service_discovery_services" {
  description = "Service discovery service ARNs for backend services"
  value       = { for team in local.teams : team => aws_service_discovery_service.backend_service[team].arn }
}

output "backend_dns_names" {
  description = "DNS names for backend services via service discovery"
  value       = { for team in local.teams : team => "${team}-backend.${team}.local" }
}
# AWS Assistant Agent Outputs
output "aws_assistant_ecs_cluster_name" {
  description = "Name of the AWS Assistant ECS cluster"
  value       = module.aws_assistant_ecs_cluster.name
}

output "aws_assistant_ecs_cluster_arn" {
  description = "ARN of the AWS Assistant ECS cluster"
  value       = module.aws_assistant_ecs_cluster.arn
}

output "aws_assistant_agent_service_name" {
  description = "Name of the AWS Assistant agent service"
  value       = length(local.private_subnet_ids) > 0 ? module.aws_assistant_agent_service[0].name : "not_created"
}

output "aws_assistant_agent_service_id" {
  description = "ID of the AWS Assistant agent service"
  value       = length(local.private_subnet_ids) > 0 ? module.aws_assistant_agent_service[0].id : "not_created"
}

output "aws_assistant_agent_task_role_arn" {
  description = "ARN of the AWS Assistant agent task role"
  value       = aws_iam_role.aws_assistant_agent_task_role.arn
}

output "aws_assistant_ecr_repository_url" {
  description = "URL of the AWS Assistant agent ECR repository"
  value       = aws_ecr_repository.aws_assistant_agent.repository_url
}

output "aws_assistant_service_discovery_namespace" {
  description = "Service discovery namespace for AWS Assistant agents"
  value       = aws_service_discovery_private_dns_namespace.aws_assistant_namespace.id
}

output "aws_assistant_service_discovery_service" {
  description = "Service discovery service ARN for AWS Assistant agents"
  value       = aws_service_discovery_service.aws_assistant_agent_service.arn
}

output "aws_assistant_agent_dns_name" {
  description = "DNS name for AWS Assistant agents via service discovery"
  value       = "aws-assistant-agent.aws-assistant.local"
}

# Monitoring Outputs
output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.project_name}-monitoring-dashboard"
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log group names for all services"
  value = {
    aws_assistant_agent = aws_cloudwatch_log_group.aws_assistant_agent.name
  }
}

output "cloudwatch_alarms" {
  description = "CloudWatch alarm names for monitoring"
  value = {
    agent_cpu_utilization    = aws_cloudwatch_metric_alarm.aws_assistant_agent_cpu_utilization.alarm_name
    agent_memory_utilization = aws_cloudwatch_metric_alarm.aws_assistant_agent_memory_utilization.alarm_name
    agent_running_count      = aws_cloudwatch_metric_alarm.aws_assistant_agent_running_count.alarm_name
    system_health            = aws_cloudwatch_composite_alarm.aws_assistant_system_health.alarm_name
  }
}

output "xray_sampling_rule_name" {
  description = "X-Ray sampling rule name (if enabled)"
  value       = var.enable_xray_tracing ? aws_xray_sampling_rule.aws_assistant_sampling[0].rule_name : null
}