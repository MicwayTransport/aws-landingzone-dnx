# =============================================================================
# BACKUP ACCOUNT - IDENTITY STACK
# =============================================================================
# This file configures the identity stack for the backup account.
# The backup account provides centralized backup and disaster recovery services.
# 
# STACK PURPOSE: Identity and access management for backup account
# ACCOUNT: backup (centralized backup and disaster recovery)
# REGION: ap-southeast-2
# =============================================================================

terraform {
  source = "${get_repo_root()}/identity"
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
  org_name       = local.globals.organization.name # Name of this organization (slug)

  job_function_roles = {
    enabled = false
  }

  ci_deploy = {
    enabled = false
  }

  ci_deploy_access = {
    enabled           = true
    trust_account_ids = []
    trust_arns        = []
    policy_sets       = ["ECS_DEFAULT", "SERVERLESS_DEFAULT"]
  }

  saml_provider = {
    get_from_baseline_cf_stack = false
    // existing_arn = ""
  }

  iam_password_policy = {
    enabled = true
  }

  aws_support_role = {
    enabled = true
  }

  oidc = {
    enabled = true
    vendor  = "github"
    org     = local.globals.organization.name
    roles = [
      {
        name         = "InfraDeployGitHub"
        assume_role  = "InfraDeployAccess"
        policy_sets  = ["ADMIN"]
        all_repos    = false
        repos        = [""]
      }
    ]
  }
}