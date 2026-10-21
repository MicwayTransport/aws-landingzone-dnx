# =============================================================================
# PROD ACCOUNT - SECURITY STACK
# =============================================================================
# This file configures security infrastructure for the PLACEHOLDER account.
# The PLACEHOLDER account hosts workloads.
# 
# STACK PURPOSE: Security monitoring and compliance for PLACEHOLDER account
# ACCOUNT: PLACEHOLDER 
# REGION: ap-southeast-2
# =============================================================================

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
  
  # This is the PLACEHOLDER account
  current_account = local.accounts.accounts.PLACEHOLDER
}

# Use centralized IAM role for PLACEHOLDER account
iam_role = local.accounts.iam_roles.PLACEHOLDER

dependency "logs" {
  config_path = "${get_repo_root()}/_workspaces/log-archive/ap-southeast-2/logs"
}

dependency "audit_security" {
  config_path = "${get_repo_root()}/_workspaces/audit/ap-southeast-2/security"
}

inputs = {
  # Use centralized values
  aws_region     = local.globals.default_aws_region
  aws_account_id = local.current_account.account_id
  account_name   = local.current_account.name
  organization   = local.globals.organization

  cloudtrail = {
    enabled                     = true
    role                        = "member"                                          # Member role for log-archive account
    global                      = false                                             # Not global since audit account handles global
    s3_bucket_name              = dependency.logs.outputs.cloudtrail_s3_bucket_name
    kms_key_arn                 = dependency.audit_security.outputs.cloudtrail_kms_key_arn
    log_group_retention_in_days = 365
    alarms = {
      enabled                = false
      mode                   = "full"
      chatbot_aws_account_id = local.accounts.accounts.audit.account_id
      slack_channel          = "aws-alerts"
      emails                 = []
    }
  }

  guardduty = {
    enabled          = true
    role             = "member"                                          # Member role for log-archive account
    bucket_name      = dependency.logs.outputs.guardduty_s3_bucket_name
    admin_account_id = local.accounts.accounts.audit.account_id         # Audit account is the master
    alarms = {
      enabled                = false
      chatbot_aws_account_id = local.accounts.accounts.audit.account_id
      slack_channel          = "aws-alerts"
    }
  }

  securityhub = {
    enabled          = true
    role             = "member"                                          # Member role for log-archive account
    admin_account_id = local.accounts.accounts.audit.account_id         # Audit account is the master
  }

  config = {
    enabled        = true
    global         = false                                               # Not global since audit account handles global
    role           = "member"                                            # Member role for log-archive account
    s3_bucket_name = dependency.logs.outputs.config_s3_bucket_name
    kms_key_arn    = dependency.audit_security.outputs.config_kms_key_arn
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
    { name = "redis" },
  ]
}
