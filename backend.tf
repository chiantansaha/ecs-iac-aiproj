terraform {
  backend "local" {
    path = "terraform.tfstate"
    region = "ap-southeast-2"
  }
}
