# CloudWatch Monitoring and Alarms for AWS Assistant Agent ECS Service

# CloudWatch Alarms for ECS Service Health
resource "aws_cloudwatch_metric_alarm" "aws_assistant_agent_cpu_utilization" {
  alarm_name          = "${var.project_name}-agent-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors AWS Assistant agent CPU utilization"
  alarm_actions       = var.cloudwatch_alarm_actions

  dimensions = {
    ServiceName = module.aws_assistant_agent_service[0].name
    ClusterName = module.aws_assistant_ecs_cluster.name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "aws_assistant_agent_memory_utilization" {
  alarm_name          = "${var.project_name}-agent-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors AWS Assistant agent memory utilization"
  alarm_actions       = var.cloudwatch_alarm_actions

  dimensions = {
    ServiceName = module.aws_assistant_agent_service[0].name
    ClusterName = module.aws_assistant_ecs_cluster.name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "aws_assistant_agent_running_count" {
  alarm_name          = "${var.project_name}-agent-running-count"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "RunningCount"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors AWS Assistant agent running task count"
  alarm_actions       = var.cloudwatch_alarm_actions

  dimensions = {
    ServiceName = module.aws_assistant_agent_service[0].name
    ClusterName = module.aws_assistant_ecs_cluster.name
  }

  tags = local.common_tags
}

# CloudWatch Dashboard for AWS Assistant Monitoring
resource "aws_cloudwatch_dashboard" "aws_assistant_dashboard" {
  dashboard_name = "${var.project_name}-monitoring-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", module.aws_assistant_agent_service[0].name, "ClusterName", module.aws_assistant_ecs_cluster.name],
            [".", "MemoryUtilization", ".", ".", ".", "."],
            [".", "RunningCount", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS Agent Metrics"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6

        properties = {
          query  = "SOURCE '/ecs/aws-assistant-agent' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region = var.aws_region
          title  = "AWS Assistant Agent Logs"
        }
      }
    ]
  })
}

# X-Ray Service Map for request tracing
resource "aws_xray_sampling_rule" "aws_assistant_sampling" {
  count = var.enable_xray_tracing ? 1 : 0

  rule_name      = "${var.project_name}-sampling-rule"
  priority       = 9000
  version        = 1
  reservoir_size = 1
  fixed_rate     = 0.1
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"

  tags = local.common_tags
}

# CloudWatch Log Insights Queries for troubleshooting
resource "aws_cloudwatch_query_definition" "agent_error_analysis" {
  name = "${var.project_name}-agent-error-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.aws_assistant_agent.name
  ]

  query_string = <<EOF
fields @timestamp, @message, @logStream
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
EOF
}

resource "aws_cloudwatch_query_definition" "agentcore_gateway_requests" {
  name = "${var.project_name}-agentcore-gateway-requests"

  log_group_names = [
    aws_cloudwatch_log_group.aws_assistant_agent.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /AgentCore/ or @message like /gateway/
| sort @timestamp desc
| limit 100
EOF
}

# CloudWatch Composite Alarms for overall system health
resource "aws_cloudwatch_composite_alarm" "aws_assistant_system_health" {
  alarm_name        = "${var.project_name}-system-health"
  alarm_description = "Composite alarm for overall AWS Assistant system health"
  alarm_actions     = var.cloudwatch_alarm_actions

  alarm_rule = join(" OR ", [
    "ALARM(${aws_cloudwatch_metric_alarm.aws_assistant_agent_cpu_utilization.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.aws_assistant_agent_memory_utilization.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.aws_assistant_agent_running_count.alarm_name})"
  ])

  tags = local.common_tags
}

# CloudWatch Log Metric Filters for custom metrics
resource "aws_cloudwatch_log_metric_filter" "agent_authentication_failures" {
  name           = "${var.project_name}-agent-auth-failures"
  log_group_name = aws_cloudwatch_log_group.aws_assistant_agent.name
  pattern        = "[timestamp, request_id, level=\"ERROR\", message=\"*authentication*\" || message=\"*unauthorized*\"]"

  metric_transformation {
    name      = "AgentAuthenticationFailures"
    namespace = "awsugsg/Assistant"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "agentcore_gateway_errors" {
  name           = "${var.project_name}-agentcore-gateway-errors"
  log_group_name = aws_cloudwatch_log_group.aws_assistant_agent.name
  pattern        = "[timestamp, request_id, level=\"ERROR\", message=\"*gateway*\" || message=\"*AgentCore*\"]"

  metric_transformation {
    name      = "AgentCoreGatewayErrors"
    namespace = "awsugsg/Assistant"
    value     = "1"
  }
}

# CloudWatch Alarms for custom metrics
resource "aws_cloudwatch_metric_alarm" "agent_authentication_failures" {
  alarm_name          = "${var.project_name}-agent-auth-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "AgentAuthenticationFailures"
  namespace           = "awsugsg/Assistant"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors agent authentication failures"
  alarm_actions       = var.cloudwatch_alarm_actions
  treat_missing_data  = "notBreaching"

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "agentcore_gateway_errors" {
  alarm_name          = "${var.project_name}-agentcore-gateway-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "AgentCoreGatewayErrors"
  namespace           = "awsugsg/Assistant"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors AgentCore Gateway errors"
  alarm_actions       = var.cloudwatch_alarm_actions
  treat_missing_data  = "notBreaching"

  tags = local.common_tags
}