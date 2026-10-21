# =============================================================================
# PLACEHOLDER ACCOUNT - PLATFORM DATA STACK
# =============================================================================
# This file configures data platform infrastructure for the PLACEHOLDER account.
# The PLACEHOLDER account hosts workloads.
# 
# STACK PURPOSE: Data services (RDS, ElastiCache, stateful services) for PLACEHOLDER workloads
# ACCOUNT: PLACEHOLDER
# REGION: ap-southeast-2
# =============================================================================

terraform {
  source = "${get_repo_root()}/platform-data"
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

dependency "audit_security" {
  config_path = "${get_repo_root()}/_workspaces/audit/ap-southeast-2/security"
}

dependency "network" {
  config_path = "${get_repo_root()}/_workspaces/PLACEHOLDER/ap-southeast-2/network"
}

inputs = {
  aws_region     = local.globals.default_aws_region
  aws_account_id = local.current_account.account_id
  org_name       = local.globals.org_name
  account_name   = local.current_account.name

  has_vpc       = true

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

rds = {
    serverless_dbs = []
    aurora_dbs     = []
    dbs = [
      // {
      //   name                       = "<db-name>"
      //   environment_name           = "dev"
      //   engine                     = "postgres"
      //   engine_version             = "15.5"
      //   user                       = "fmadmin"
      //   port                       = 5432
      //   instance_class             = "db.t4g.small"
      //   allocated_storage          = 100
      //   storage_encrypted          = true
      //   snapshot_identifier        = "arn:aws:rds:ap-southeast-2:465067946441:snapshot:dev-fm-from-legacy"
      //   auto_minor_version_upgrade = true
      //   kms_name                   = "aws/rds"
      //   backup                     = true
      //   retention                  = 7
      //   multi_az                   = false
      //   apply_immediately          = false
      //   allow_from_vpn             = false
      //   allow_cidrs                = ["10.135.0.0/16"]
      //   secret_method              = "secretsmanager"
      //   create_db_parameter_group  = true
      //   parameter_group_name       = "dev-custom-postgres14"
      //   family                     = "postgres15"
      //   backup_window              = "02:00-04:00"
      //   db_parameters              = []
      //   shutdown_schedule = {
      //     enabled    = true
      //     cron_start = "0 20 ? * SUN-THU *" # 7 AM
      //     cron_stop  = "0 11 ? * MON-FRI *" # 10 PM
      //   }
      // }
    ]
  }

  buckets = [
    // {
    //   name          = "fm-attachments-dev"
    //   kms_name      = "cmk/s3"
    //   sse_algorithm = "aws:kms"
    //   log_bucket    = false
    //   versioning    = true
    //   lifecycle_rules = [
    //     {
    //       id     = "Rule-1"
    //       status = "Enabled"
    //       transition = [
    //         {
    //           days          = 150
    //           storage_class = "STANDARD_IA"
    //         }
    //       ]
    //     }
    //   ]
    // }
  ]

  mq = {
    brokers = [
      // {
      //   name               = "dev-fm-message-bus"
      //   deployment_mode    = "ACTIVE_STANDBY_MULTI_AZ"
      //   kms_name           = "cmk/mq-brokers"
      //   configurations     = []
      //   engine_type        = "ActiveMQ"
      //   engine_version     = "5.16.7"
      //   host_instance_type = "mq.t3.micro"
      //   allow_cidr_blocks  = "10.135.64.0/18" ## private subnets
      // }
    ]
  }


  elasticache = {
    redis = [
      // {
      //   name             = "fm"
      //   env              = "dev"
      //   redis_parameters = []
      //   version          = "7.0"
      //   node_type        = "cache.t3.micro"
      //   multi_az_enabled = false
      //   redis_failover   = false
      //   secret_method    = "secretmanager"
      //   allowed_cidr = [
      //     {
      //       cidr        = "10.135.64.0/18"
      //       description = "Redis access from private subnet"
      //       name        = "dev-fm-redis-private-access"
      //     }
      //   ]
      //   at_rest_encryption_enabled = true
      //   transit_encryption_enabled = true
      //   kms_name                   = "cmk/redis" # created at security stack
      //   auto_minor_version_upgrade = true
      //   user_group_ids             = ["dev-fm"]
      // }
    ]
    redis_users = {
      users = [
        // {
        //   user_id       = "default"
        //   user_name     = "default"
        //   access_string = "off -@all"
        // }
      ]
      user_groups = [
        // {
        //   user_group_id = "fm"
        //   user_ids      = ["dev-api-server"]
        // }
      ]
    }
  }

}
