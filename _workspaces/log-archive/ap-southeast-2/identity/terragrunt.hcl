# =============================================================================
# LOG-ARCHIVE ACCOUNT - IDENTITY STACK
# =============================================================================
# This file configures the identity stack for the log-archive account.
# The log-archive account provides centralized, immutable log storage for compliance.
# 
# STACK PURPOSE: Identity and access management for log-archive account
# ACCOUNT: log-archive (centralized logging storage)
# REGION: ap-southeast-2
# =============================================================================

terraform {
  source = "${get_repo_root()}/identity"
}

include "remote_state" {
  path = find_in_parent_folders("remote-state.hcl")
}

# Load centralized configurations
locals {
  globals  = read_terragrunt_config(find_in_parent_folders("globals.hcl")).locals
  accounts = read_terragrunt_config(find_in_parent_folders("accounts.hcl")).locals

  # This is the log-archive account - centralized logging storage
  current_account = local.accounts.accounts.log-archive
}

# Use centralized IAM role for log-archive account
iam_role = local.accounts.iam_roles.log-archive

inputs = {
  aws_region     = local.globals.default_aws_region
  aws_account_id = local.current_account.account_id
  account_name   = local.current_account.name
  org_name       = local.globals.organization.name

  # Log-archive account specific identity configuration
  job_function_roles = {
    enabled = true # Enable job function roles for log management
  }

  ci_deploy = {
    enabled = false # CI/CD typically not deployed in log-archive account
  }

  ci_deploy_access = {
    enabled           = true
    trust_account_ids = values(local.accounts.workload_account_ids) # Allow workload accounts to assume roles
    trust_arns        = []
    policy_sets       = ["LOG_ARCHIVE_ADMIN", "COMPLIANCE_READ"] # Log-archive-specific policy sets
  }

  saml_provider = {
    get_from_baseline_cf_stack = true # Use baseline SAML provider for log-archive access
  }

  iam_password_policy = {
    enabled = true # Enforce strong password policy in log-archive account
  }

  aws_support_role = {
    enabled = true # Enable AWS Support access for log-archive account
  }

  oidc = {
    enabled = true
    vendor  = "github"
    org     = local.globals.organization.name
    roles = [
      {
        name        = "LogArchiveDeployGitHub"
        assume_role = "InfraDeployAccess"
        policy_sets = ["LOG_ARCHIVE_DEPLOY"] # Limited deployment permissions for log infrastructure
        all_repos   = false
        repos       = ["aws-iac", "log-infrastructure"]
      }
    ]
  }

  # Log-archive account specific settings
  account_type        = "log-archive"
  is_log_archive      = true
  centralized_logging = true
  immutable_storage   = true
}