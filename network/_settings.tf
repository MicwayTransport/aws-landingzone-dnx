provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.global_tags
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
  default_tags {
    tags = var.global_tags
  }
}
locals {
  stack_name = "network"
}
