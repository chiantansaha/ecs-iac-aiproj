# CloudWatch X-Ray sampling rule for tracing
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
