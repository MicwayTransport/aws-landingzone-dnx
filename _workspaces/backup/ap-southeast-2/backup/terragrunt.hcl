## This file configures the backup management for the backup account (central backup).

terraform {
  source = "${get_repo_root()}/backup"
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

  # This is the backup account
  current_account = local.accounts.accounts.backup
}

# Use centralized IAM role
iam_role = local.accounts.iam_roles.backup

inputs = {
  aws_region     = local.globals.default_aws_region
  aws_account_id = local.current_account.account_id
  account_name   = local.current_account.name
  org_name       = local.globals.org_name
  account_type   = "backup"

  backup = [
    {
      name                                  = "${local.globals.org_name}-backup-central"
      enabled                               = true
      kms_name                              = local.globals.kms_keys.backup
      selection_tag_key                     = "Backup"
      selection_tag_value                   = "true"
      enable_aws_backup_vault_notifications = true
      backup_vault_events = [
        "BACKUP_JOB_STARTED",
        "BACKUP_JOB_COMPLETED",
        "BACKUP_JOB_FAILED",
        "RESTORE_JOB_STARTED",
        "RESTORE_JOB_COMPLETED",
        "RESTORE_JOB_FAILED",
        "COPY_JOB_STARTED",
        "COPY_JOB_SUCCESSFUL",
        "COPY_JOB_FAILED",
        "RECOVERY_POINT_MODIFIED"
      ]
      notification_slack_endpoint = ""
      notification_email          = local.accounts.accounts.backup.email
      min_retention_days          = 7
      max_retention_days          = 365
      allow_from_account_ids      = values(local.accounts.existing_workload_account_ids)

      rules = [
        {
          rule_name                = "continuous"
          enable_continuous_backup = true
          schedule                 = "cron(0 9 ? * * *)" # 09:00am UTC -> 7:00pm AEST
          start_window             = 60
          completion_window        = 120
          lifecycle = {
            delete_after = 7
          }
        },
        {
          rule_name                = "weekly"
          enable_continuous_backup = false
          schedule                 = "cron(0 12 ? * SUN *)" # 12:00pm UTC -> 10:00pm AEST
          start_window             = 60
          completion_window        = 120
          lifecycle = {
            cold_storage_after = 30
            delete_after       = 120
          }
        },
        {
          rule_name                = "monthly"
          enable_continuous_backup = false
          schedule                 = "cron(0 12 L * ? *)" # 12:00pm UTC -> 10:00pm AEST
          start_window             = 60
          completion_window        = 120
          lifecycle = {
            cold_storage_after = 90
            delete_after       = 365
          }
        }
      ]
    }
  ]

  notifications = {
    enabled        = true
    slack_endpoint = ""
    email          = local.accounts.accounts.backup.email
    account_ids    = values(local.accounts.all_account_ids)
  }

  notifications_sns_topic_arn = ""
}
