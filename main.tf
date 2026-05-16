provider "aws" {
  region = var.region
}

# Data sources are defined in data.tf

# Local values for common configuration
locals {
  # Common tags for all resources
  common_tags = merge(var.tags, {
    Environment = "dev"
    Project     = "awsugsg"
  })

  # Team-specific tags function
  team_tags = {
    for team in local.teams : team => merge(local.common_tags, {
      Team = team
      app  = "awsugsg-${team}"
    })
  }
}
