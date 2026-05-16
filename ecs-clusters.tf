# Multi-team ECS clusters
module "ecs_cluster" {
  for_each = toset(local.teams)

  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "~> 6.7.0"

  name = "awsugsg-${each.value}"

  # Container Insights configurable
  setting = concat(
    [
      {
        name  = "containerInsights"
        value = var.enable_ecs_container_insights ? "enabled" : "disabled"
      }
    ],
    var.enable_ecs_dual_stack_ipv6 ? [
      {
        name  = "dualStackIPv6"
        value = "enabled"
      }
    ] : []
  )

  tags = local.team_tags[each.value]
}

# Multi-team CloudWatch log groups
resource "aws_cloudwatch_log_group" "ecs" {
  for_each = toset(local.teams)

  name              = "/ecs/awsugsg-${each.value}"
  retention_in_days = var.log_retention_days

  tags = local.team_tags[each.value]
}

