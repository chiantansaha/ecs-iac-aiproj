# Multi-team Frontend Services
module "frontend_service" {
  for_each = length(local.private_subnet_ids) > 0 ? toset(local.teams) : toset([])

  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.7.0"

  name        = "${each.value}-frontend"
  cluster_arn = module.ecs_cluster[each.value].arn

  cpu    = 512
  memory = 1024

  # Runtime platform for ARM64 support
  runtime_platform = {
    operating_system_family = "LINUX"
    cpu_architecture        = var.ecs_runtime_platform
  }

  capacity_provider_strategy = {
    fargate_spot = {
      capacity_provider = "FARGATE_SPOT"
      weight            = 100
      base              = 0
    }
  }

  ignore_task_definition_changes = false
  desired_count                  = var.desired_count

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200

  # New: Enable automatic rollback on deployment interruption
  sigint_rollback = true

  # Enable availability zone rebalancing
  availability_zone_rebalancing = var.ecs_availability_zone_rebalancing

  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 3

  autoscaling_policies = {
    cpu = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        target_value = 90
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
      }
    }
    memory = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        target_value = 90
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageMemoryUtilization"
        }
      }
    }
  }

  enable_execute_command = false
  tasks_iam_role_arn     = aws_iam_role.frontend_task_role[each.value].arn
  task_exec_iam_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"

  create_tasks_iam_role  = false
  create_task_definition = true

  container_definitions = {
    (var.container_name) = {
      image = "${aws_ecr_repository.frontend[each.value].repository_url}:latest"

      # Performance optimization: Enable init process for better signal handling
      init_process_enabled = true

      portMappings = [
        {
          name          = "app"
          protocol      = "tcp"
          containerPort = local.team_ports[each.value].frontend
        }
      ]

      environment = [
        {
          "name" : "PORT",
          "value" : tostring(local.team_ports[each.value].frontend)
        },
        {
          "name" : "HEALTHCHECK",
          "value" : var.health_check
        },
        {
          "name" : "BACKEND_URL",
          "value" : "http://${each.value}-backend.${each.value}.local:${local.team_ports[each.value].backend}"
        },
        {
          "name" : "TEAM_NAME",
          "value" : each.value
        },
        {
          "name" : "STREAMLIT_SERVER_BASE_URL_PATH",
          "value" : "/${each.value}"
        }
      ]

      readonlyRootFilesystem    = false
      enable_cloudwatch_logging = true
      log_configuration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/awsugsg-${each.value}"
          "awslogs-region"        = local.region
          "awslogs-stream-prefix" = "frontend"
        }
      }
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["frontend-${each.value}"].arn
      container_name   = var.container_name
      container_port   = local.team_ports[each.value].frontend
    }
  }

  subnet_ids = [local.private_subnet_ids[0]]

  tags = merge(local.team_tags[each.value], {
    Type = "frontend"
  })
}

# Multi-team Backend Services
module "backend_service" {
  for_each = length(local.private_subnet_ids) > 0 ? toset(local.teams) : toset([])

  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.7.0"

  name        = "${each.value}-backend"
  cluster_arn = module.ecs_cluster[each.value].arn

  cpu    = 256
  memory = 512

  # Runtime platform for ARM64 support
  runtime_platform = {
    operating_system_family = "LINUX"
    cpu_architecture        = var.ecs_runtime_platform
  }

  capacity_provider_strategy = {
    fargate_spot = {
      capacity_provider = "FARGATE_SPOT"
      weight            = 100
      base              = 0
    }
  }

  ignore_task_definition_changes = false
  desired_count                  = var.desired_count

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200

  # New: Enable automatic rollback on deployment interruption
  sigint_rollback = true

  # Enable availability zone rebalancing
  availability_zone_rebalancing = var.ecs_availability_zone_rebalancing

  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 3

  autoscaling_policies = {
    cpu = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        target_value = 90
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
      }
    }
    memory = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        target_value = 90
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageMemoryUtilization"
        }
      }
    }
  }

  enable_execute_command = false
  tasks_iam_role_arn     = aws_iam_role.backend_task_role[each.value].arn
  task_exec_iam_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"

  create_tasks_iam_role  = false
  create_task_definition = true

  # Service Discovery Configuration
  service_registries = {
    registry_arn = aws_service_discovery_service.backend_service[each.value].arn
  }

  container_definitions = {
    backend = {
      image = "${aws_ecr_repository.backend[each.value].repository_url}:latest"

      # Performance optimization: Enable init process for better signal handling
      init_process_enabled = true

      portMappings = [
        {
          name          = "backend"
          protocol      = "tcp"
          containerPort = local.team_ports[each.value].backend
        }
      ]

      environment = [
        {
          "name" : "PORT",
          "value" : tostring(local.team_ports[each.value].backend)
        },
        {
          "name" : "TEAM_NAME",
          "value" : each.value
        }
      ]

      readonlyRootFilesystem    = false
      enable_cloudwatch_logging = true
      log_configuration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/awsugsg-${each.value}"
          "awslogs-region"        = local.region
          "awslogs-stream-prefix" = "backend"
        }
      }
    }
  }

  subnet_ids = [local.private_subnet_ids[0]]

  tags = merge(local.team_tags[each.value], {
    Type = "backend"
  })
}

# AWS Assistant Agent Service
module "aws_assistant_agent_service" {
  count = length(local.private_subnet_ids) > 0 ? 1 : 0

  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.7.0"

  name        = "aws-assistant-agent"
  cluster_arn = module.aws_assistant_ecs_cluster.arn

  cpu    = 512
  memory = 1024

  capacity_provider_strategy = {
    fargate = {
      capacity_provider = "FARGATE"
      weight            = 100
      base              = 1
    }
  }

  ignore_task_definition_changes = false
  desired_count                  = 2

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 10

  autoscaling_policies = {
    cpu = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        target_value = 70
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
      }
    }
    memory = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        target_value = 80
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageMemoryUtilization"
        }
      }
    }
  }

  enable_execute_command = true
  tasks_iam_role_arn     = aws_iam_role.aws_assistant_agent_task_role.arn
  task_exec_iam_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"

  create_tasks_iam_role  = false
  create_task_definition = true

  # Service Discovery Configuration
  service_registries = {
    registry_arn = aws_service_discovery_service.aws_assistant_agent_service.arn
  }

  container_definitions = {
    aws-assistant-agent = {
      image = "${aws_ecr_repository.aws_assistant_agent.repository_url}:latest"

      # Performance optimization: Enable init process for better signal handling
      init_process_enabled = true

      portMappings = [
        {
          name          = "agent"
          protocol      = "tcp"
          containerPort = 8080
        }
      ]

      environment = [
        {
          "name" : "PORT",
          "value" : "8080"
        },
        {
          "name" : "AWS_REGION",
          "value" : local.region
        },
        {
          "name" : "AGENTCORE_GATEWAY_URL",
          "value" : "https://bedrock-agentcore.${local.region}.amazonaws.com"
        },
        {
          "name" : "LOG_LEVEL",
          "value" : var.log_level
        },
        {
          "name" : "RETRY_MAX_ATTEMPTS",
          "value" : "3"
        },
        {
          "name" : "RETRY_BACKOFF_MULTIPLIER",
          "value" : "2"
        },
        {
          "name" : "IAM_LAMBDA_FUNCTION_ARN",
          "value" : "arn:aws:lambda:${local.region}:${local.account_id}:function:iam-mcp-server"
        },
        {
          "name" : "CLOUDTRAIL_LAMBDA_FUNCTION_ARN",
          "value" : "arn:aws:lambda:${local.region}:${local.account_id}:function:cloudtrail-mcp-server"
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      readonlyRootFilesystem    = false
      enable_cloudwatch_logging = true
      log_configuration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/aws-assistant-agent"
          "awslogs-region"        = local.region
          "awslogs-stream-prefix" = "agent"
        }
      }
    }
  }

  subnet_ids = local.private_subnet_ids

  tags = merge(local.common_tags, {
    Type = "aws-assistant-agent"
  })
}
