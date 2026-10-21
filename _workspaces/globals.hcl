# =============================================================================
# GLOBAL CONFIGURATION
# =============================================================================
# This file contains values that are IDENTICAL across ALL stacks and ALL accounts
# 
# USED BY: Every terragrunt.hcl file in every stack/account combination
# USAGE: local.globals.default_aws_region, local.globals.organization, etc.
# 
# WHEN TO UPDATE: 
# - Changing AWS region for entire organization
# - Changing organization name
# - Updating IAM role naming patterns
# =============================================================================

locals {
  # Organization settings - used in all stacks for tagging and naming
  organization = { 
    name = "organization-name"  # Placeholder for organization name
  }
  org_name = "organization-name"  # Legacy format for older modules

  # AWS region - consistent across all accounts and stacks
  # Used in: provider configuration, resource creation, ARN construction
  # CUSTOMIZE: Set your preferred default region
  default_aws_region = "ap-southeast-2"  # Default region for all stacks

  # IAM role naming pattern - used to generate role ARNs for cross-account access
  # Pattern: arn:aws:iam::{account_id}:role/InfraDeployAccess
  # Used by: terragrunt iam_role configuration
  iam_role_pattern = "arn:aws:iam::%s:role/InfraDeployAccess"

  # Centralized KMS keys for backup encryption
  # USED BY: backup stack for encryption of backup vaults
  # This is a centralized key used across environments
  # if empty, it will use the default AWS KMS key for backups
  kms_keys = {
    backup = ""  # Centralized backup KMS key
  }

  # ==========================================================================
  # HELPER FUNCTIONS FOR CONFIGURATION INHERITANCE
  # ==========================================================================

  # Generate standardized resource names with organization prefix
  # USAGE: local.globals.resource_name("s3-bucket", "logs")
  # RESULT: "organization-name-s3-bucket-logs"
  resource_name = {
    for type in ["s3-bucket", "kms-key", "sns-topic", "iam-role", "lambda-function"] :
    type => "${local.organization.name}-${type}"
  }

  # Common tags applied to all resources across all accounts and stacks
  # USED BY: All terraform resources for consistent tagging
  common_tags = {
    Organization = local.organization.name
    ManagedBy    = "terraform"
    Foundation   = "dnx-foundation"
    CreatedBy    = "terragrunt"
  }

  # Global tags applied via the aws provider `default_tags` block in every stack.
  # USED BY: All stacks (_settings.tf) — passed as the `global_tags` input through
  # the `include "globals"` block, so every AWS resource inherits these tags.
  # WHEN TO UPDATE: Adding/removing a tag that must exist on every AWS resource
  # across the entire foundation (e.g. partner program IDs, cost allocation tags).
  global_tags = {
    "aws-apn-id" = "pc:3dzx7t9es09krh7lxyl30xkj5"
  }

  # Regional configuration support
  # USED BY: Multi-region deployments and region-specific settings
  regions = {
    primary   = local.default_aws_region
    secondary = "us-east-1"  # Common secondary region for global services

    # Region-specific settings
    settings = {
      "ap-southeast-2" = {
        availability_zones = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
        nat_gateway_count  = 2
        backup_region      = "us-east-1"
      }
      "us-east-1" = {
        availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
        nat_gateway_count  = 2
        backup_region      = "ap-southeast-2"
      }
    }
  }

}

# =============================================================================
# INPUTS
# =============================================================================
# These inputs are automatically merged into every stack that `include "globals"`.
# No need to re-declare them in individual terragrunt.hcl files.
# =============================================================================
inputs = {
  global_tags = local.global_tags
}

# =============================================================================
# EXAMPLES OF USAGE IN TERRAGRUNT FILES:
# =============================================================================
# locals {
#   globals = read_terragrunt_config(find_in_parent_folders("globals.hcl")).locals
# }
# 
# inputs = {
#   aws_region   = local.globals.default_aws_region
#   organization = local.globals.organization
#   org_name     = local.globals.org_name
# }
# =============================================================================
