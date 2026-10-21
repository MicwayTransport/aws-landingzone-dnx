# This file configures the platform infrastructure for the PLACEHOLDER environment.
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
  remote_state_config = read_terragrunt_config(find_in_parent_folders("remote-state.hcl"))

  # This is the PLACEHOLDER account
  current_account = local.accounts.accounts.PLACEHOLDER
}

# Use centralized IAM role
iam_role = local.accounts.iam_roles.PLACEHOLDER

dependency "network" {
  config_path = "${get_repo_root()}/_workspaces/PLACEHOLDER/ap-southeast-2/network"
}

inputs = {
  aws_region     = local.globals.default_aws_region
  aws_account_id = local.current_account.account_id
  org_name       = local.globals.org_name
  account_name   = local.current_account.name 

  has_vpc                     = true
   # Remote state config for audit security - Terraform module will use this to create terraform_remote_state data source
  audit_security_remote_state = {
    backend = local.remote_state_config.remote_state.backend
    config = merge(
      local.remote_state_config.remote_state.config,
      { key = "audit/ap-southeast-2/security/terraform.tfstate" }
    )
  }
  
  # These will be retrieved in the Terraform module using terraform_remote_state data source
  notifications_sns_topic_arn = null  # Will be set via data.terraform_remote_state.audit_security.outputs.notifications_sns_topic_arn

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
        hostnames                                 = ["hello.${local.environments.domain_patterns.PLACEHOLDER}"],
        hostname_create                           = true,
        hostname_redirects                        = "",
        hosted_zone                               = local.environments.domain_patterns.PLACEHOLDER,
        alb_only                                  = true,
        paths                                     = ["/*"],
        healthcheck_path                          = "/",
        service_health_check_grace_period_seconds = 30,
        cloudwatch_logs_export                    = false,
        autoscaling_min                           = 1,
        autoscaling_max                           = 4,
        test_traffic_route_listener_arn           = false,
        create_iam_codedeployrole                 = false,
        launch_type                               = "FARGATE",
        fargate_spot                              = false,
        memory                                    = 1024,
        cpu                                       = 512,
        container_port                            = 3000,
      }
    ]
    workers = [
      // {
      //   name                   = "track_simulator"
      //   cluster_name           = "<customer-cluster>"
      //   desired_count          = 1
      //   launch_type            = "FARGATE"
      //   cloudwatch_logs_export = false
      //   shutdown_schedule = {
      //     enabled    = true
      //     cron_start = "cron(0 19 ? * SUN-THU *)"
      //     cron_stop  = "cron(0 11 ? * MON-FRI *)"
      //   }
      // }
    ]
  }

  wafv2 = [
    // {
    //   name : "waf-ap-default",
    //   enabled : true,
    //   cluster_name : ["<customer-cluster>"]
    // }
  ]

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
    cloudwatch_logs_export_bucket = null  # Will be set via data.terraform_remote_state.audit_security.outputs.logs_s3_bucket_name
  }

  frontend = {
    apps = []
  }

  efs = {
    volumes = [
      // {
      //   name        = "COMPACT_TITLES"
      //   ecs_cluster = "<customer-cluster>"
      // }
    ]
  }

  ses = [
    // {
    //   name        = "ap-southeast-2"
    //   hosted_zone = "<customer-hosted_zone>"
    //   # hostname = "mail.PLACEHOLDER.firemapper.app"
    //   domain      = "<customer-domain>"
    //   sender_mail = "xxxx@xxxx.xxx"
    // }
  ]
}
