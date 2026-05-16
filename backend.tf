terraform {
  backend "s3" {
    bucket = "terraform-state-awsugsg-739907928373"
    key    = "awsugsg/terraform.tfstate"
    region = "ap-southeast-2"
  }
}
