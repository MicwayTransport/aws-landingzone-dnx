# This file configures the platform-data infrastructure for the dev environment.
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

  rds = {
    serverless_dbs = []
    aurora_dbs     = []
    dbs = []
  }

  buckets = []

  mq = {
    brokers = []
  }


  elasticache = {
    redis = []
    redis_users = {
      users = []
      user_groups = []
    }
  }

}
