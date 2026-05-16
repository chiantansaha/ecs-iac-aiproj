# Multi-team ECR repositories
resource "aws_ecr_repository" "frontend" {
  for_each = toset(local.teams)

  name                 = "awsugsg-${each.value}-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.team_tags[each.value], {
    Type = "frontend"
  })
}

resource "aws_ecr_repository" "backend" {
  for_each = toset(local.teams)

  name                 = "awsugsg-${each.value}-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.team_tags[each.value], {
    Type = "backend"
  })
}


