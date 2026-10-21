# =============================================================================
# SHARED SERVICES ACCOUNT - IDENTITY STACK
# =============================================================================
# This file configures the identity stack for the shared services account.
# The shared services account hosts shared resources like CI/CD, monitoring tools, and shared infrastructure.
# 
# STACK PURPOSE: Identity and access management for shared services account
# ACCOUNT: shared-services (shared resources and tools across organization)
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
  
  # This is the shared-services account
  current_account = local.accounts.accounts.shared-services
}

# Use centralized IAM role
iam_role = local.accounts.iam_roles.shared-services


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
        repos        = ["machship-aws-iac"]
      }
    ]
  }
}