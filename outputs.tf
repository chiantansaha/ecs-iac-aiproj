output "teams" {
  description = "List of teams deployed"
  value       = local.teams
}

output "region" {
  description = "The AWS region"
  value       = local.region
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
  value       = { for team in local.teams : team => length(local.ecs_subnet_ids) > 0 ? module.frontend_service[team].name : "not_created" }
}

output "frontend_service_ids" {
  description = "The IDs of the frontend services"
  value       = { for team in local.teams : team => length(local.ecs_subnet_ids) > 0 ? module.frontend_service[team].id : "not_created" }
}

output "backend_service_names" {
  description = "The names of the backend services"
  value       = { for team in local.teams : team => length(local.ecs_subnet_ids) > 0 ? module.backend_service[team].name : "not_created" }
}

output "backend_service_ids" {
  description = "The IDs of the backend services"
  value       = { for team in local.teams : team => length(local.ecs_subnet_ids) > 0 ? module.backend_service[team].id : "not_created" }
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
# Monitoring Outputs
output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.project_name}-monitoring-dashboard"
}

output "xray_sampling_rule_name" {
  description = "X-Ray sampling rule name (if enabled)"
  value       = var.enable_xray_tracing ? aws_xray_sampling_rule.aws_assistant_sampling[0].rule_name : null
}