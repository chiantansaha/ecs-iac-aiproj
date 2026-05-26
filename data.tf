data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

# Get default VPC if no VPC ID is provided
data "aws_vpc" "default" {
  count   = var.vpc_id == "" ? 1 : 0
  default = true
}

# Get specified VPC if VPC ID is provided
data "aws_vpc" "selected" {
  count = var.vpc_id != "" ? 1 : 0
  id    = var.vpc_id
}

# Use either the specified VPC or default VPC
locals {
  vpc_id = var.vpc_id != "" ? data.aws_vpc.selected[0].id : data.aws_vpc.default[0].id
}

# Try to find private subnets by tag first, then by route table association
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["*private*", "*Private*", "*PRIVATE*"]
  }
}

# Fallback: find all subnets if no tagged private subnets found
data "aws_subnets" "all_subnets" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["*public*", "*Public*", "*PUBLIC*"]
  }
}

data "aws_route_tables" "private" {
  count  = length(data.aws_subnets.private.ids) > 0 ? 1 : 0
  vpc_id = local.vpc_id
  filter {
    name   = "association.subnet-id"
    values = data.aws_subnets.private.ids
  }
}

locals {
  region             = data.aws_region.current.id
  account_id         = data.aws_caller_identity.current.account_id
  # Use public subnets for ECS tasks to ensure internet connectivity for ECR
  # If no public subnets found, fall back to private subnets (may need VPC endpoints)
  ecs_subnet_ids     = length(data.aws_subnets.public.ids) > 0 ? data.aws_subnets.public.ids : (length(data.aws_subnets.private.ids) > 0 ? data.aws_subnets.private.ids : data.aws_subnets.all_subnets.ids)
  # Use private subnets for ALB (internal load balancer)
  private_subnet_ids = length(data.aws_subnets.private.ids) > 0 ? data.aws_subnets.private.ids : data.aws_subnets.all_subnets.ids
  public_subnet_ids  = data.aws_subnets.public.ids
}
