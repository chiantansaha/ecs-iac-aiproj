# Multi-team frontend security group rules
resource "aws_security_group_rule" "frontend_egress_https" {
  for_each = length(local.private_subnet_ids) > 0 ? toset(local.teams) : toset([])

  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.frontend_service[each.value].security_group_id
}

resource "aws_security_group_rule" "frontend_egress_http" {
  for_each = length(local.private_subnet_ids) > 0 ? toset(local.teams) : toset([])

  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.frontend_service[each.value].security_group_id
}

# Allow ingress from ALB subnet range on application port
resource "aws_security_group_rule" "frontend_ingress_app" {
  for_each = length(local.private_subnet_ids) > 0 ? toset(local.teams) : toset([])

  type              = "ingress"
  from_port         = local.team_ports[each.value].frontend
  to_port           = local.team_ports[each.value].frontend
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = module.frontend_service[each.value].security_group_id
}

# Allow frontend to communicate with same-team backend
resource "aws_security_group_rule" "frontend_egress_to_backend" {
  for_each = length(local.private_subnet_ids) > 0 ? toset(local.teams) : toset([])

  type                     = "egress"
  from_port                = local.team_ports[each.value].backend
  to_port                  = local.team_ports[each.value].backend
  protocol                 = "tcp"
  source_security_group_id = module.backend_service[each.value].security_group_id
  security_group_id        = module.frontend_service[each.value].security_group_id
}

# Multi-team backend security group rules
resource "aws_security_group_rule" "backend_egress_https" {
  for_each = length(local.private_subnet_ids) > 0 ? toset(local.teams) : toset([])

  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.backend_service[each.value].security_group_id
}

# Allow only same-team frontend to communicate with backend
resource "aws_security_group_rule" "backend_ingress_from_frontend" {
  for_each = length(local.private_subnet_ids) > 0 ? toset(local.teams) : toset([])

  type                     = "ingress"
  from_port                = local.team_ports[each.value].backend
  to_port                  = local.team_ports[each.value].backend
  protocol                 = "tcp"
  source_security_group_id = module.frontend_service[each.value].security_group_id
  security_group_id        = module.backend_service[each.value].security_group_id
}

# AWS Assistant Agent security group rules
resource "aws_security_group_rule" "aws_assistant_agent_egress_https" {
  count = length(local.private_subnet_ids) > 0 ? 1 : 0

  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.aws_assistant_agent_service[0].security_group_id
}

resource "aws_security_group_rule" "aws_assistant_agent_egress_http" {
  count = length(local.private_subnet_ids) > 0 ? 1 : 0

  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.aws_assistant_agent_service[0].security_group_id
}

# Allow health check access on port 8080
resource "aws_security_group_rule" "aws_assistant_agent_ingress_health" {
  count = length(local.private_subnet_ids) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = module.aws_assistant_agent_service[0].security_group_id
}
