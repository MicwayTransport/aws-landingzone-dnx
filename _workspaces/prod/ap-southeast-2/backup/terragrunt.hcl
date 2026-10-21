## This file configures the backup management for the prod account.

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

  # This is the prod account
  current_account = local.accounts.accounts.prod
}

# Use centralized IAM role
iam_role = local.accounts.iam_roles.prod

inputs = {
  aws_region     = local.globals.default_aws_region
  aws_account_id = local.current_account.account_id
  account_name   = local.current_account.name
  org_name       = local.globals.org_name
  account_type   = "workload"

   backup = [
    {
      name                                  = "${local.current_account.name}-${local.globals.org_name}-backup"
      enabled                               = true
      kms_name                              = local.globals.kms_keys.backup
      selection_tag_key                     = "Backup"
      selection_tag_value                   = "true"
      enable_aws_backup_vault_notifications = true
      backup_vault_events                   = ["BACKUP_JOB_FAILED", "COPY_JOB_FAILED"]
      notification_slack_endpoint           = ""
      notification_email                    = local.accounts.accounts.backup.email
      min_retention_days                    = 7
      max_retention_days                    = 30
      allow_from_account_ids                = [local.accounts.accounts.backup.account_id]

      rules = [
        {
          rule_name                = "continuous"
          enable_continuous_backup = true
          schedule                 = "cron(0 9 ? * * *)" # 09:00am UTC -> 7:00pm AEST
          start_window             = 60
          completion_window        = 120
          lifecycle = {
            # Note: cold_storage_after is NOT allowed with continuous backup
            delete_after = 7  # Keep continuous backup for 7 days (point-in-time recovery)
          }
          copy_actions = [{
            destination_vault_arn = "arn:aws:backup:${local.globals.default_aws_region}:${local.accounts.accounts.backup.account_id}:backup-vault:${local.globals.org_name}-backup-central"
            lifecycle = {
              # Note: cold_storage_after is NOT allowed with continuous backup (even for copies)
              delete_after = 30  # Keep copy for 30 days in central vault
            }
          }]
        },
        {
          rule_name                = "weekly"
          enable_continuous_backup = false
          schedule                 = "cron(0 12 ? * SUN *)" # 12:00pm UTC -> 10:00pm AEST
          start_window             = 60
          completion_window        = 120
          lifecycle = {
            cold_storage_after = 14   # Move to cold storage after 14 days (cost optimization)
            delete_after       = 90   # Keep for 90 days total
          }
          copy_actions = [{
            destination_vault_arn = "arn:aws:backup:${local.globals.default_aws_region}:${local.accounts.accounts.backup.account_id}:backup-vault:${local.globals.org_name}-backup-central"
            lifecycle = {
              cold_storage_after = 90    # In central vault: cold storage after 90 days
              delete_after       = 365   # In central vault: keep for 1 year
            }
          }]
        },
        {
          rule_name                = "monthly"
          enable_continuous_backup = false
          schedule                 = "cron(0 12 1 * ? *)" # Monthly on 1st day at 12:00pm UTC
          start_window             = 60
          completion_window        = 120
          lifecycle = {
            cold_storage_after = 1     # Immediately move to cold storage (very cost effective)
            delete_after       = 365   # Keep for 1 year locally
          }
          copy_actions = [{
            destination_vault_arn = "arn:aws:backup:${local.globals.default_aws_region}:${local.accounts.accounts.backup.account_id}:backup-vault:${local.globals.org_name}-backup-central"
            lifecycle = {
              cold_storage_after = 1     # Immediately to cold storage in central vault
              delete_after       = 2555  # Keep for 7 years in central vault (compliance)
            }
          }]
        }
      ]

      copy_action = {
        aws_account_id = local.accounts.accounts.backup.account_id
      }
    }
  ]

  notifications_sns_topic_arn = ""
}
