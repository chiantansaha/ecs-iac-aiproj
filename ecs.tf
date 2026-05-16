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

