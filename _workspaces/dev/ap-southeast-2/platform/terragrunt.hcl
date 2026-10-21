# This file configures the platform infrastructure for the dev environment.
terraform {
  source = "${get_repo_root()}/platform"
}

include "remote_state" {
  path = find_in_parent_folders("remote-state.hcl")
}

# Include centralized configurations
include "globals" {
  path = find_in_parent_folders("globals.hcl")
}

include "accounts" {
  path = find_in_parent_folders("accounts.hcl")
}

include "environments"{
  path = find_in_parent_folders("environments.hcl")
}

# Load centralized configurations
locals {
  globals  = read_terragrunt_config(find_in_parent_folders("globals.hcl")).locals
  accounts = read_terragrunt_config(find_in_parent_folders("accounts.hcl")).locals
  environments = read_terragrunt_config(find_in_parent_folders("environments.hcl")).locals

  # This is the dev account
  current_account = local.accounts.accounts.dev
}

# Use centralized IAM role
iam_role = local.accounts.iam_roles.dev

dependency "security_audit" {
  config_path = "${get_repo_root()}/_workspaces/audit/ap-southeast-2/security"
}

dependency "network" {
  config_path = "${get_repo_root()}/_workspaces/dev/ap-southeast-2/network"
}

inputs = {
  aws_region     = local.globals.default_aws_region
  aws_account_id = local.current_account.account_id
  org_name       = local.globals.org_name  # Name of this organization (slug)
  account_name   = local.current_account.name 

  has_vpc                     = true
  notifications_sns_topic_arn = dependency.security_audit.outputs.notifications_sns_topic_arn # from Security account

  ec2 = [
    // {
    //   name : "test",
    //   instance_type : "t3.large",
    //   ami_id : "ami-09aad00dc4657a2ac",
    //   sg_cidr_blocks : ["10.87.0.0/16"]
    // }
  ]

  ecr = {
    trust_account_ids = []
    kms_key_arn       = ""
    lifecycle_policy  = ""
    scan_type         = "BASIC"
    repositories = [
      {
        name = "hello"
      }
    ]
  }

  ecs = {
    create_iam_service_linked_role = false
    tasks                          = []
    clusters = [
      {
        name : "default",
        fargate_only : true,
        alb : true,
        alb_internal : false,
        certificate_arn : dependency.network.outputs.acm_certificate["default"].arn
      },
      // {
      //   name : "<customer-worker-cluster>",
      //   fargate_only : true,
      //   alb : false,
      //   alb_internal : false
      // }
    ]
    apps = [
      {
        name                                      = "hello",
        cluster_name                              = "default",
        hostnames                                 = ["hello.${local.environments.domain_patterns.dev}"],
        hostname_create                           = true,
        hostname_redirects                        = "",
        hosted_zone                               = local.environments.domain_patterns.dev,
        alb_only                                  = true,
        paths                                     = ["/*"],
        healthcheck_path                          = "/",
        service_health_check_grace_period_seconds = 30,
        cloudwatch_logs_export                    = false,
        autoscaling_min                           = 1,
        autoscaling_max                           = 2,
        test_traffic_route_listener_arn           = false,
        create_iam_codedeployrole                 = false,
        launch_type                               = "FARGATE",
        fargate_spot                              = true,
        memory                                    = 512,
        cpu                                       = 256,
        container_port                            = 3000,
      }
    ]
    workers = []
  }

  wafv2 = []

  ssm = {
    strings         = {}
    secured_strings = []
  }

  secrets_manager = {
    secrets = [
      { name = "/app/default/hello" }
    ]
  }

  log_exporter = {
    enabled                       = false
    cloudwatch_logs_export_bucket = dependency.security_audit.outputs.logs_s3_bucket_name
  }

  frontend = {
    apps = []
  }

  efs = {
    volumes = []
  }

  ses = []
}
