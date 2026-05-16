# Service Discovery Namespaces for each team
resource "aws_service_discovery_private_dns_namespace" "team_namespace" {
  for_each = toset(local.teams)

  name        = "${each.value}.local"
  description = "Service discovery namespace for ${each.value} development environment"
  vpc         = var.vpc_id

  tags = merge(local.team_tags[each.value], {
    Name = "${each.value}.local"
    Type = "service-discovery-namespace"
  })
}

# Service Discovery Service for Backend Services
resource "aws_service_discovery_service" "backend_service" {
  for_each = toset(local.teams)

  name          = "${each.value}-backend"
  force_destroy = true

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.team_namespace[each.value].id

    dns_records {
      ttl  = 60
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = merge(local.team_tags[each.value], {
    Name = "${each.value}-backend"
    Type = "service-discovery-service"
  })
}

# Service Discovery Namespace for AWS Assistant Agents
resource "aws_service_discovery_private_dns_namespace" "aws_assistant_namespace" {
  name        = "aws-assistant.local"
  description = "Service discovery namespace for AWS Assistant agents"
  vpc         = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "aws-assistant.local"
    Type = "service-discovery-namespace"
  })
}

# Service Discovery Service for AWS Assistant Agents
resource "aws_service_discovery_service" "aws_assistant_agent_service" {
  name          = "aws-assistant-agent"
  force_destroy = true

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.aws_assistant_namespace.id

    dns_records {
      ttl  = 60
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = merge(local.common_tags, {
    Name = "aws-assistant-agent"
    Type = "service-discovery-service"
  })
}
