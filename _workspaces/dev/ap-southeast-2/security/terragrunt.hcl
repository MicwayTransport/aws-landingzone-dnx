terraform {
  source = "${get_repo_root()}/security"
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

# Load centralized configurations
locals {
  globals  = read_terragrunt_config(find_in_parent_folders("globals.hcl")).locals
  accounts = read_terragrunt_config(find_in_parent_folders("accounts.hcl")).locals
  
  # This is the dev account
  current_account = local.accounts.accounts.dev
}

# Use centralized IAM role
iam_role = local.accounts.iam_roles.dev

dependency "logs" {
  config_path = "${get_repo_root()}/_workspaces/log-archive/ap-southeast-2/logs"
}

dependency "audit" {
  config_path = "${get_repo_root()}/_workspaces/audit/ap-southeast-2/security"
}

inputs = {
  # Use centralized values
  aws_region     = local.globals.default_aws_region
  aws_account_id = local.current_account.account_id
  account_name   = local.current_account.name
  organization   = local.globals.organization

  cloudtrail = {
    enabled                     = true                                              # enable when NOT using organization cloudtrail
    role                        = "member"                                          # It creates the KMS key to be used by members
    global                      = true                                              # enable in one region only to avoid duplication of events
    s3_bucket_name              = dependency.logs.outputs.cloudtrail_s3_bucket_name # cloudtrail bucket name - get it from log archive phase 1 output
    kms_key_arn                 = dependency.logs.outputs.cloudtrail_kms_key_arn
    log_group_retention_in_days = 365
    alarms = {
      enabled                = false
      mode                   = "full"
      chatbot_aws_account_id = local.accounts.accounts.audit.account_id # Use centralized audit account ID
      slack_channel          = "aws-alerts"
      emails                 = [] # optional
    }
  }

  guardduty = {
    enabled          = true
    role             = "member"
    bucket_name      = dependency.logs.outputs.guardduty_s3_bucket_name # Log archive bucket (you need to run log workspace first)
    admin_account_id = local.accounts.accounts.audit.account_id          # Use centralized audit account ID
    alarms = {
      enabled                = false
      chatbot_aws_account_id = local.accounts.accounts.audit.account_id # Use centralized audit account ID
      slack_channel          = "aws-alerts"   # thats the sns topic the chatbox is subscring to ?
    }
  }

  securityhub = {
    enabled          = true
    role             = "member"
    admin_account_id = local.accounts.accounts.audit.account_id # Use centralized audit account ID
  }

  config = {
    enabled        = true
    global         = true # enable in one region only to avoid duplication of events
    role           = "member"
    s3_bucket_name = dependency.logs.outputs.config_s3_bucket_name # config bucket name - get it from log archive phase 1 output
    kms_key_arn    = dependency.audit.outputs.config_kms_key_arn
  }

  detective = {
    enabled = false
  }

  ebs_encryption_by_default = {
    enabled = true
  }

  kms_cmk = [
    { name = "rds" },
    { name = "backup" },
    { name = "s3" },
  ]
}
