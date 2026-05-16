module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 10.2.0"

  name = "awsugsg-shared-alb"

  enable_deletion_protection = false
  load_balancer_type         = "application"
  internal                   = true

  # Cost optimization: Set minimum capacity for low-traffic workloads (60% savings)
  # Disabled due to account capacity limits
  # minimum_load_balancer_capacity = {
  #   capacity_units = var.alb_minimum_capacity_units
  # }

  # Performance optimizations
  enable_http2                     = true
  enable_cross_zone_load_balancing = true
  enable_zonal_shift               = true # New: Improved availability
  enable_waf_fail_open             = var.enable_alb_waf_fail_open
  idle_timeout                     = var.alb_idle_timeout
  desync_mitigation_mode           = "defensive"
  drop_invalid_header_fields       = true

  vpc_id  = local.vpc_id
  subnets = slice(data.aws_subnets.private.ids, 0, 2)

  security_group_ingress_rules = merge(
    {
      for idx, ip in var.allowed_ips :
      "http_${idx}" => merge(
        {
          from_port   = 80
          to_port     = 80
          ip_protocol = "tcp"
          description = "HTTP web traffic from ${ip}"
        },
        strcontains(ip, ":") ? { cidr_ipv6 = ip } : { cidr_ipv4 = ip }
      )
    },
    var.acm_certificate_arn != "" || var.create_self_signed_cert ? {
      for idx, ip in var.allowed_ips :
      "https_${idx}" => merge(
        {
          from_port   = 443
          to_port     = 443
          ip_protocol = "tcp"
          description = "HTTPS web traffic from ${ip}"
        },
        strcontains(ip, ":") ? { cidr_ipv6 = ip } : { cidr_ipv4 = ip }
      )
    } : {}
  )

  security_group_egress_rules = {
    vpc_cidr = {
      ip_protocol = "-1"
      cidr_ipv4   = data.aws_vpc.selected.cidr_block
    }
    https_outbound = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "HTTPS outbound"
    }
  }

  listeners = merge(
    {
      http = {
        port     = 80
        protocol = "HTTP"

        forward = {
          target_group_key = "frontend-team1"
        }

        rules = merge(
          {
            for idx, team in local.teams : "team_${team}" => {
              priority = idx + 1
              actions = [{
                forward = {
                  target_group_key = "frontend-${team}"
                }
              }]
              conditions = [{
                path_pattern = {
                  values = ["/${team}/*"]
                }
              }]
            }
          },
          {
            for idx, team in local.teams : "team_${team}_no_slash" => {
              priority = idx + 5
              actions = [{
                forward = {
                  target_group_key = "frontend-${team}"
                }
              }]
              conditions = [{
                path_pattern = {
                  values = ["/${team}"]
                }
              }]
            }
          },
          {
            for idx, team in local.teams : "team_${team}_static" => {
              priority = idx + 9
              actions = [{
                forward = {
                  target_group_key = "frontend-${team}"
                }
              }]
              conditions = [{
                path_pattern = {
                  values = ["/${team}/static/*"]
                }
              }]
            }
          },
          {
            for idx, team in local.teams : "team_${team}_stcore" => {
              priority = idx + 13
              actions = [{
                forward = {
                  target_group_key = "frontend-${team}"
                }
              }]
              conditions = [{
                path_pattern = {
                  values = ["/${team}/_stcore/*"]
                }
              }]
            }
          }
        )
      }
    },
    var.acm_certificate_arn != "" || var.create_self_signed_cert ? {
      https = {
        port            = 443
        protocol        = "HTTPS"
        certificate_arn = var.acm_certificate_arn != "" ? var.acm_certificate_arn : aws_acm_certificate.self_signed[0].arn

        forward = {
          target_group_key = "frontend-team1"
        }

        rules = merge(
          {
            for idx, team in local.teams : "team_${team}" => {
              priority = idx + 1
              actions = [{
                forward = {
                  target_group_key = "frontend-${team}"
                }
              }]
              conditions = [{
                path_pattern = {
                  values = ["/${team}/*"]
                }
              }]
            }
          },
          {
            for idx, team in local.teams : "team_${team}_no_slash" => {
              priority = idx + 5
              actions = [{
                forward = {
                  target_group_key = "frontend-${team}"
                }
              }]
              conditions = [{
                path_pattern = {
                  values = ["/${team}"]
                }
              }]
            }
          },
          {
            for idx, team in local.teams : "team_${team}_static" => {
              priority = idx + 9
              actions = [{
                forward = {
                  target_group_key = "frontend-${team}"
                }
              }]
              conditions = [{
                path_pattern = {
                  values = ["/${team}/static/*"]
                }
              }]
            }
          },
          {
            for idx, team in local.teams : "team_${team}_stcore" => {
              priority = idx + 13
              actions = [{
                forward = {
                  target_group_key = "frontend-${team}"
                }
              }]
              conditions = [{
                path_pattern = {
                  values = ["/${team}/_stcore/*"]
                }
              }]
            }
          }
        )
      }
    } : {}
  )

  target_groups = {
    for team in local.teams : "frontend-${team}" => {
      name             = "awsugsg-${team}-frontend-v2"
      backend_protocol = "HTTP"
      port             = local.team_ports[team].frontend
      target_type      = "ip"

      # Performance optimization: Enable cross-zone load balancing
      load_balancing_cross_zone_enabled = "use_load_balancer_configuration"

      # Enable sticky sessions
      stickiness = {
        enabled         = true
        type            = "lb_cookie"
        cookie_duration = 86400 # 24 hours
      }

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30 # Increased to 30s for cost reduction
        matcher             = "200-299"
        path                = "/${team}/_stcore/health" # Streamlit health endpoint with base path
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      create_attachment = false
    }
  }

  tags = merge(local.common_tags, {
    Purpose = "shared-alb"
    app     = "awsugsg"
  })
}
