# =============================================================================
# ACCOUNT REGISTRY
# =============================================================================
# This file is the SINGLE SOURCE OF TRUTH for all AWS account information
# 
# USED BY: All terragrunt.hcl files that need account IDs or IAM roles
# USAGE: local.accounts.accounts.dev.account_id, local.accounts.iam_roles.dev
# 
# WHEN TO UPDATE:
# - Creating new AWS accounts
# - Changing account IDs (rare)
# - Adding new environments
# - Updating email addresses
# =============================================================================

locals {
  # ==========================================================================
  # ACCOUNT DEFINITIONS
  # ==========================================================================
  accounts = {
    # ------------------------------------------------------------------------
    # CORE AWS ORGANIZATION ACCOUNTS (EXISTING)
    # These are foundational accounts for security, logging, backup, etc.
    # ------------------------------------------------------------------------
    root = {
      account_id = "PLACEHOLDER-ROOT"  # UPDATE WHEN ACCOUNT IS CREATED
      name       = "root"
      email      = "aws-organization-name+root@organization-name.com"
      # USED BY: Organization management, billing
    }
    audit = {
      account_id = "PLACEHOLDER-AUDIT"  # UPDATE WHEN ACCOUNT IS CREATED
      name       = "audit"
      email      = "aws-organization-name+audit@organization-name.com"
      # USED BY: Security monitoring, compliance, notifications
    }
    log-archive = {
      account_id = "PLACEHOLDER-LOG-ARCHIVE"  # UPDATE WHEN ACCOUNT IS CREATED
      name       = "log-archive"
      email      = "aws-organization-name+log-archive@organization-name.com"
      # USED BY: Centralized logging (CloudTrail, GuardDuty, Config)
    }
    backup = {
      account_id = "PLACEHOLDER-BACKUP"  # UPDATE WHEN ACCOUNT IS CREATED
      name       = "backup"
      email      = "aws-organization-name+backup@organization-name.com"
      # USED BY: Cross-account backups, disaster recovery
    }
    network-hub = {
      account_id = "PLACEHOLDER-NETWORK-HUB"  # UPDATE WHEN ACCOUNT IS CREATED
      name       = "network-hub"
      email      = "aws-organization-name+network-hub@organization-name.com"
      # USED BY: Transit Gateway, VPN connections, DNS
    }
    shared-services = {
      account_id = "PLACEHOLDER-SHARED-SERVICES"  # UPDATE WHEN ACCOUNT IS CREATED
      name       = "shared-services"
      email      = "aws-organization-name+shared-services@organization-name.com"
      # USED BY: Shared resources like CI/CD, monitoring tools
    }
    
    # ------------------------------------------------------------------------
    # WORKLOAD ACCOUNTS
    # These accounts host application workloads and environments
    # ------------------------------------------------------------------------
    dev = {
      account_id = "PLACEHOLDER-DEV"  # UPDATE WHEN ACCOUNT IS CREATED
      name       = "dev"
      email      = "aws-organization-name+dev@organization-name.com"
      # USED BY: Development environment workloads
    }

    stage = {
      account_id = "PLACEHOLDER-STAGE"  # UPDATE WHEN ACCOUNT IS CREATED
      name       = "stage"
      email      = "aws-organization-name+stage@organization-name.com"
      # WILL BE USED BY: Staging environment workloads
    }
    prod = {
      account_id = "PLACEHOLDER-PROD"   # UPDATE WHEN ACCOUNT IS CREATED
      name       = "prod"
      email      = "aws-organization-name+prod@organization-name.com"
      # WILL BE USED BY: Production environment workloads
    }
    secure-prod = {
      account_id = "PLACEHOLDER-SECURE-PROD"  # UPDATE WHEN ACCOUNT IS CREATED
      name       = "secure-prod"
      email      = "aws-organization-name+secure-prod@organization-name.com"
      # WILL BE USED BY: High-security production workloads
    }
  }
  
  # ==========================================================================
  # HELPER FUNCTIONS
  # ==========================================================================
  
  # Generate IAM role ARNs for cross-account access
  # USED BY: terragrunt iam_role configuration
  # EXAMPLE: local.accounts.iam_roles.dev = "arn:aws:iam::123456789012:role/InfraDeployAccess"
  iam_roles = {
    for env, config in local.accounts : env => format("arn:aws:iam::%s:role/InfraDeployAccess", config.account_id)
  }
  
  # Get all account IDs as a map
  # USED BY: Cross-account policies, log bucket permissions
  # EXAMPLE: { dev = "123456789012", audit = "123456789013", ... }
  all_account_ids = {
    for env, config in local.accounts : env => config.account_id
  }
  
  # Get only EXISTING workload account IDs (excludes placeholders)
  # USED BY: Current log bucket permissions, existing cross-account access
  # EXAMPLE: { dev = "123456789012" }
  existing_workload_account_ids = {
    dev = local.accounts.dev.account_id
    # Add stage, prod, secure-prod here when they're created
  }
  
  # Get all workload account IDs (including future ones with placeholders)
  # USED BY: Future-ready configurations, templates
  # EXAMPLE: { dev = "123456789012", stage = "PLACEHOLDER-STAGE", ... }
  all_workload_account_ids = {
    dev         = local.accounts.dev.account_id
    stage       = local.accounts.stage.account_id
    prod        = local.accounts.prod.account_id
    secure-prod = local.accounts.secure-prod.account_id
  }
}

# =============================================================================
# EXAMPLES OF USAGE IN TERRAGRUNT FILES:
# =============================================================================
# locals {
#   accounts = read_terragrunt_config(find_in_parent_folders("accounts.hcl")).locals
#   current_account = local.accounts.accounts.dev  # or .prod, .stage, etc.
# }
# 
# iam_role = local.accounts.iam_roles.dev
# 
# inputs = {
#   aws_account_id = local.current_account.account_id
#   account_name   = local.current_account.name
#   
#   # For cross-account access:
#   admin_account_id = local.accounts.accounts.audit.account_id
#   allow_from_account_ids = local.accounts.existing_workload_account_ids
# }
# =============================================================================
