data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}

data "aws_route_tables" "private" {
  vpc_id = var.vpc_id
  filter {
    name   = "association.subnet-id"
    values = data.aws_subnets.private.ids
  }
}

locals {
  region             = data.aws_region.current.id
  account_id         = data.aws_caller_identity.current.account_id
  vpc_id             = var.vpc_id
  private_subnet_ids = data.aws_subnets.private.ids
  public_subnet_ids  = data.aws_subnets.public.ids
}
