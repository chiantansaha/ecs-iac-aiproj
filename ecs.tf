# Multi-team IAM task roles for frontend
resource "aws_iam_role" "frontend_task_role" {
  for_each = toset(local.teams)

  name = "${each.value}-frontend-tasks"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.team_tags[each.value], {
    Type = "frontend"
  })
}

resource "aws_iam_role_policy" "frontend_task_policy" {
  for_each = toset(local.teams)

  name = "${each.value}-frontend-task-policy"
  role = aws_iam_role.frontend_task_role[each.value].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock-agentcore:InvokeAgentRuntime",
          "bedrock-agentcore:InvokeAgentRuntimeForUser",
          "bedrock-agentcore:ListAgentRuntimes",
          "bedrock-agentcore:ListAgentRuntimeVersions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/meridian/*"
      }
    ]
  })
}

# Multi-team IAM task roles for backend
resource "aws_iam_role" "backend_task_role" {
  for_each = toset(local.teams)

  name = "${each.value}-backend-tasks"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.team_tags[each.value], {
    Type = "backend"
  })
}

resource "aws_iam_role_policy" "backend_task_policy" {
  for_each = toset(local.teams)

  name = "${each.value}-backend-task-policy"
  role = aws_iam_role.backend_task_role[each.value].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock-agentcore:InvokeAgentRuntime",
          "bedrock-agentcore:InvokeAgentRuntimeForUser",
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/meridian/*"
      }
    ]
  })
}

# Attach ReadOnlyAccess policy to backend task roles
resource "aws_iam_role_policy_attachment" "backend_readonly_access" {
  for_each = toset(local.teams)

  role       = aws_iam_role.backend_task_role[each.value].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# AWS Assistant Agent IAM task role
resource "aws_iam_role" "aws_assistant_agent_task_role" {
  name = "aws-assistant-agent-tasks"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Type = "aws-assistant-agent"
  })
}

resource "aws_iam_role_policy" "aws_assistant_agent_task_policy" {
  name = "aws-assistant-agent-task-policy"
  role = aws_iam_role.aws_assistant_agent_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock-agentcore:InvokeAgentRuntime",
          "bedrock-agentcore:InvokeAgentRuntimeForUser",
          "bedrock-agentcore:ListAgentRuntimes",
          "bedrock-agentcore:ListAgentRuntimeVersions",
          "bedrock-agentcore:GetAgentRuntime",
          "bedrock-agentcore:CreateAgentSession",
          "bedrock-agentcore:InvokeAgent"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          "arn:aws:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-iam-mcp-server",
          "arn:aws:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:${var.project_name}-cloudtrail-mcp-server"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/aws-assistant-agent:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "aws:RequestedRegion" = data.aws_region.current.id
          }
        }
      }
    ]
  })
}
