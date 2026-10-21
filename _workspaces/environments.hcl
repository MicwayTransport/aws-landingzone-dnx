# =============================================================================
# ENVIRONMENT-SPECIFIC PATTERNS
# =============================================================================
# This file contains patterns and configurations that VARY by environment
# but follow predictable patterns (like domain names, CIDR blocks)
# 
# USED BY: Stacks that need environment-specific values (network, platform)
# USAGE: local.environments.domain_patterns.dev, local.environments.vpc_cidrs.prod
# 
# WHEN TO UPDATE:
# - Adding new environments
# - Changing domain naming patterns
# - Updating VPC CIDR allocation strategy
# - Modifying common service configurations
# =============================================================================

locals {
  # ==========================================================================
  # DOMAIN PATTERNS
  # ==========================================================================
  # Consistent domain naming across environments
  # USED BY: network stack (Route53), platform stack (ALB hostnames)
  # PATTERN: {environment}.cloud.organization-name.com
  domain_patterns = {
    dev         = "dev.organization-name.cloud"
    stage       = "stage.organization-name.cloud"       # 🔄 Ready for when stage account is created
    prod        = "prod.organization-name.cloud"        # 🔄 Ready for when prod account is created
    secure-prod = "secure-prod.organization-name.cloud" # 🔄 Ready for when secure-prod account is created
    audit       = "audit.organization-name.cloud"       # For audit/monitoring dashboards
  }
  
  # ==========================================================================
  # VPC CIDR PATTERNS
  # ==========================================================================
  # Non-overlapping CIDR blocks for each environment
  # USED BY: network stack for VPC creation
  # PATTERN: 10.{X}7.0.0/16 where X increments by 1 for each environment
  vpc_cidrs = {
    dev         = "10.47.0.0/16"  # ✅ Based on existing network/dev config
    stage       = "10.57.0.0/16"  # 🔄 Ready for stage environment
    prod        = "10.67.0.0/16"  # ✅ Based on existing network/prod config  
    secure-prod = "10.77.0.0/16"  # 🔄 Ready for secure-prod environment
    audit       = "10.87.0.0/16"  # For audit account networking if needed
  }
  
}

# =============================================================================
# EXAMPLES OF USAGE IN TERRAGRUNT FILES:
# =============================================================================
# 
# # In network/{env}/terragrunt.hcl:
# locals {
#   environments = read_terragrunt_config(find_in_parent_folders("environments.hcl")).locals
# }
# inputs = {
#   vpc_cidr = local.environments.vpc_cidrs.dev  # Gets "10.47.0.0/16"
#   domain   = local.environments.domain_patterns.dev  # Gets "dev.cloud.organization-name.com"
# }
# 
# # In platform/{env}/terragrunt.hcl:
# inputs = {
#   hostname = "api.${local.environments.domain_patterns.dev}"  # Gets "api.dev.cloud.organization-name.com"
# }
# 
# # In security/logs/terragrunt.hcl:
# inputs = {
#   log_buckets = merge(local.environments.log_buckets_default, {
#     # Environment-specific overrides here
#   })
# }
# =============================================================================
