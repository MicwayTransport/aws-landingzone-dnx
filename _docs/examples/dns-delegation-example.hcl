# =============================================================================
# DNS DELEGATION STACK - EXAMPLE CONFIGURATION
# =============================================================================
# This example shows how to configure automated NS record delegation from
# a parent Route53 zone to child zones in workload accounts.
#
# USE CASE: Delegate subdomains from shared-services to workload accounts
# EXAMPLE: infra.example.com → dev.infra.example.com, prod.infra.example.com
# =============================================================================

terraform {
  source = "${get_repo_root()}/dns-delegation"
}

include "remote_state" {
  path = find_in_parent_folders("remote-state.hcl")
}

include "globals" {
  path = find_in_parent_folders("globals.hcl")
}

include "accounts" {
  path = find_in_parent_folders("accounts.hcl")
}

include "environments" {
  path = find_in_parent_folders("environments.hcl")
}

locals {
  globals      = read_terragrunt_config(find_in_parent_folders("globals.hcl")).locals
  accounts     = read_terragrunt_config(find_in_parent_folders("accounts.hcl")).locals
  environments = read_terragrunt_config(find_in_parent_folders("environments.hcl")).locals
  
  current_account = local.accounts.accounts.shared-services
}

iam_role = local.accounts.iam_roles.shared-services

# =============================================================================
# DEPENDENCIES
# =============================================================================
# Dependency on parent zone (where NS records will be created)
dependency "parent_network" {
  config_path = "${get_repo_root()}/_workspaces/shared-services/${local.globals.default_aws_region}/network"
}

# Dependencies on child zones (to get their nameservers)
dependency "dev_network" {
  config_path = "${get_repo_root()}/_workspaces/dev/${local.globals.default_aws_region}/network"
  
  # Mock outputs allow planning before child zones are deployed
  mock_outputs = {
    route53_name_servers = {
      "dev.infra.example.com" = ["ns-mock1.awsdns.com", "ns-mock2.awsdns.com", "ns-mock3.awsdns.com", "ns-mock4.awsdns.com"]
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "prod_network" {
  config_path = "${get_repo_root()}/_workspaces/prod/${local.globals.default_aws_region}/network"
  
  mock_outputs = {
    route53_name_servers = {
      "prod.infra.example.com" = ["ns-mock1.awsdns.com", "ns-mock2.awsdns.com", "ns-mock3.awsdns.com", "ns-mock4.awsdns.com"]
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

# =============================================================================
# INPUTS
# =============================================================================
inputs = {
  aws_region     = local.globals.default_aws_region
  aws_account_id = local.current_account.account_id
  
  # Parent zone information (from shared-services network stack)
  parent_zone_id   = dependency.parent_network.outputs.route53_hosted_zone_ids["infra.example.com"]
  parent_zone_name = "infra.example.com"
  
  # Child zone delegations
  # Add one entry per environment that needs delegation
  child_zones = {
    dev = {
      subdomain    = "dev"
      name_servers = dependency.dev_network.outputs.route53_name_servers["dev.infra.example.com"]
    }
    prod = {
      subdomain    = "prod"
      name_servers = dependency.prod_network.outputs.route53_name_servers["prod.infra.example.com"]
    }
    # Add more environments as needed:
    # qa = {
    #   subdomain    = "qa"
    #   name_servers = dependency.qa_network.outputs.route53_name_servers["qa.infra.example.com"]
    # }
  }
}

# =============================================================================
# DEPLOYMENT ORDER
# =============================================================================
# 1. Deploy parent zone (shared-services network stack)
# 2. Deploy child zones (dev, prod network stacks)
# 3. Deploy this dns-delegation stack
# 4. Verify: dig NS dev.infra.example.com
# 5. ACM certificates in child zones will auto-validate
# =============================================================================
