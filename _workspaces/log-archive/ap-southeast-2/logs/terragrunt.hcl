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

include "environments" {
  path = find_in_parent_folders("environments.hcl")
}


# Load centralized configurations
locals {
  globals      = read_terragrunt_config(find_in_parent_folders("globals.hcl")).locals
  accounts     = read_terragrunt_config(find_in_parent_folders("accounts.hcl")).locals
  environments = read_terragrunt_config(find_in_parent_folders("environments.hcl")).locals
  # log-archive account is where the actual log files are stored
  current_account = local.accounts.accounts.log-archive
}

# Use centralized IAM role for log-archive account
iam_role = local.accounts.iam_roles.log-archive

inputs = {
  aws_region     = local.globals.default_aws_region
  aws_account_id = local.current_account.account_id
  account_name   = local.current_account.name
  organization   = local.globals.organization

  log_buckets = {
    # Allow ALL existing accounts to send logs to the centralized log-archive account
    # This includes: audit, root, backup, network-hub, shared-services, dev
    enabled                       = true
    transition_to_glacier_in_days = 90
    allow_from_account_ids = {
      root            = local.accounts.accounts.root.account_id
      backup          = local.accounts.accounts.backup.account_id
      log-archive     = local.accounts.accounts.log-archive.account_id
      audit           = local.accounts.accounts.audit.account_id
      network-hub     = local.accounts.accounts.network-hub.account_id
      shared-services = local.accounts.accounts.shared-services.account_id
      dev             = local.accounts.accounts.dev.account_id
      # 🔄 Add stage, prod, secure-prod here when those accounts are created
    }
  }
}
