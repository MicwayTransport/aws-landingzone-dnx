terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

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
  stack_name = "backup"
  account_type = {
    workload = "workload"
    backup   = "backup"
  }
}