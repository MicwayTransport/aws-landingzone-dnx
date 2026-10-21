terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.68.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.2"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.global_tags
  }
}
provider "awscc" {
  region = var.aws_region
}

provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
  default_tags {
    tags = var.global_tags
  }
}

provider "aws" {
  region = "us-west-1"
  alias  = "us-west-1"
  default_tags {
    tags = var.global_tags
  }
}

locals {
  stack_name = "platform-data"
}
