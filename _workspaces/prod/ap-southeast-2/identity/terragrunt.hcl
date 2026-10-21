## This file configures the identity management for the prod account.

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

  # This is the prod account
  current_account = local.accounts.accounts.prod
}

# Use centralized IAM role
iam_role = local.accounts.iam_roles.prod

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
    enabled = false
    vendor  = "github"
    org     = local.globals.organization.name # Name of this organization (slug) 
    roles = [
      {
        name         = "CIDeployGitHub"
        assume_role  = "CIDeployAccess"
        policy_sets = ["ECS_DEFAULT", "SERVERLESS_DEFAULT"]
        all_repos    = true
      },
      {
        name         = "InfraDeployGitHub"
        assume_role  = "InfraDeployAccess"
        policy_sets  = ["ADMIN"]
        all_repos    = false
        repos        = ["bemoved-aws-iac"]
      }
    ]
  }
}
