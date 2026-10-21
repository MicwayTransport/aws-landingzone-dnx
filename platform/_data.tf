data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  has_ecs_clusters     = length(try(var.ecs.clusters, [])) > 0
  has_eks_clusters     = try(var.eks.enabled, false)
  is_ci_deploy_enabled = try(var.gitlab_runner.ci_deploy.enabled, false)
  has_ec2_instance     = length(try(var.ec2, [])) > 0
  has_vpc              = (try(var.has_vpc, false) || local.has_eks_clusters || local.has_ecs_clusters || local.is_ci_deploy_enabled || local.has_ec2_instance)
}

data "aws_vpc" "selected" {
  count = local.has_vpc ? 1 : 0
  filter {
    name   = "tag:EnvName"
    values = [var.account_name]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnets" "public" {
  count = local.has_vpc ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected[0].id]
  }

  filter {
    name   = "tag:Scheme"
    values = ["public"]
  }
}

data "aws_subnets" "private" {
  count = local.has_vpc ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected[0].id]
  }

  filter {
    name   = "tag:Scheme"
    values = ["private"]
  }
}

data "aws_subnet" "private" {
  count  = try(length(data.aws_subnets.private[0].ids), 0)
  vpc_id = data.aws_vpc.selected[0].id
  id     = tolist(data.aws_subnets.private[0].ids)[count.index]
  filter {
    name   = "tag:Scheme"
    values = ["private"]
  }
}

data "aws_subnets" "secure" {
  count = local.has_vpc ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected[0].id]
  }

  filter {
    name   = "tag:Scheme"
    values = ["secure"]
  }
}

data "aws_ami" "ldap" {
  count       = try(var.ldap.count, 0) > 0 && length(try(var.ldap.ami_version, "")) > 0 ? 1 : 0
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "tag:Name"
    values = ["packer-openldap-${try(var.ldap.ami_version, "")}"]
  }
}
