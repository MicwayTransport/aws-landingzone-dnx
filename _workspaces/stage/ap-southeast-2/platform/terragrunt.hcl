# =============================================================================
# STAGE ACCOUNT - PLATFORM STACK
# =============================================================================
# This file configures platform infrastructure for the stage account.
# The stage account hosts staging environment workloads and pre-production testing.
# 
# STACK PURPOSE: Platform services (ECS, EKS, compute) for stage workloads
# ACCOUNT: stage (staging and integration testing)
# REGION: ap-southeast-2
# =============================================================================

terraform {
  source = "${get_repo_root()}/platform"
}

include "remote_state" {
  path = find_in_parent_folders("remote-state.hcl")
}

# Dependencies - automatically resolved from deployment dependency management
dependencies {
  paths = local.deployment_deps.get_terragrunt_dependencies.stage.platform.all_dependencies
}

# Load centralized configurations
locals {
  globals      = read_terragrunt_config(find_in_parent_folders("globals.hcl")).locals
  accounts     = read_terragrunt_config(find_in_parent_folders("accounts.hcl")).locals
  environments = read_terragrunt_config(find_in_parent_folders("environments.hcl")).locals

  # This is the stage account - staging and integration testing
  current_account = local.accounts.accounts.stage
}

# Use centralized IAM role for stage account
iam_role = local.accounts.iam_roles.stage

inputs = {
  aws_region     = local.globals.default_aws_region
  aws_account_id = local.current_account.account_id
  account_name   = local.current_account.name
  org_name       = local.globals.organization.name

  # ECS configuration for stage environment
  ecs = {
    enabled            = true
    name               = "stage-ecs"
    capacity_providers = ["FARGATE", "FARGATE_SPOT", "EC2"] # Include EC2 for production-like testing
    default_capacity_provider_strategy = [
      {
        capacity_provider = "FARGATE"
        weight            = 70
        base              = 2
      },
      {
        capacity_provider = "FARGATE_SPOT"
        weight            = 30
        base              = 0
      }
    ]
  }

  # EKS configuration for stage environment
  eks = {
    enabled = true
    name    = "stage-eks"
    version = "1.28" # Use stable version for stage
    node_groups = [
      {
        name           = "stage-workers"
        instance_types = ["t3.large", "t3a.large"] # Production-like instances
        min_size       = 2
        max_size       = 10
        desired_size   = 3
        capacity_type  = "ON_DEMAND" # On-demand for production-like testing
      }
    ]
    fargate_profiles = [
      {
        name = "stage-fargate"
        selectors = [
          {
            namespace = "stage"
            labels = {
              compute-type = "fargate"
            }
          }
        ]
      }
    ]
  }

  # ECR configuration for stage environment
  ecr = {
    enabled = true
    repositories = [
      {
        name                 = "stage-app"
        image_tag_mutability = "IMMUTABLE" # Immutable tags for production-like testing
        scan_on_push         = true
        lifecycle_policy = {
          rules = [
            {
              rulePriority = 1
              description  = "Keep last 20 stage images"
              selection = {
                tagStatus     = "tagged"
                tagPrefixList = ["stage", "v"]
                countType     = "imageCountMoreThan"
                countNumber   = 20
              }
              action = {
                type = "expire"
              }
            }
          ]
        }
      }
    ]
  }

  # Application Load Balancer for stage environment
  ecs_app = {
    enabled         = true
    name            = "stage-app"
    hostname        = "api.${local.environments.domain_patterns.stage}"
    certificate_arn = "" # Will be populated from network stack outputs
    health_check = {
      enabled             = true
      healthy_threshold   = 3
      interval            = 30
      matcher             = "200"
      path                = "/health"
      port                = "traffic-port"
      protocol            = "HTTP"
      timeout             = 5
      unhealthy_threshold = 3
    }
  }

  # CloudFront distribution for stage environment
  cloudfront_ecs = {
    enabled  = true # Enable for production-like testing
    name     = "stage-cloudfront"
    hostname = "cdn.${local.environments.domain_patterns.stage}"
  }

  # Frontend application configuration
  frontend_app = {
    enabled        = true
    name           = "stage-frontend"
    hostname       = "app.${local.environments.domain_patterns.stage}"
    s3_bucket_name = "${local.globals.organization.name}-frontend-stage"
  }

  # EFS configuration for stage environment
  efs = {
    enabled                         = true
    name                            = "stage-efs"
    performance_mode                = "generalPurpose"
    throughput_mode                 = "provisioned"
    provisioned_throughput_in_mibps = 50 # Higher throughput for production-like testing
  }

  # Secrets Manager configuration
  secrets_manager = {
    enabled = true
    secrets = [
      {
        name        = "stage/database/credentials"
        description = "Database credentials for stage environment"
      },
      {
        name        = "stage/api/keys"
        description = "API keys for stage environment"
      }
    ]
  }

  # SSM Parameter Store configuration
  ssm = {
    enabled = true
    parameters = [
      {
        name  = "/stage/config/app_name"
        value = "stage-application"
        type  = "String"
      },
      {
        name  = "/stage/config/environment"
        value = "staging"
        type  = "String"
      }
    ]
  }

  # KMS configuration for platform services
  kms = {
    enabled = true
    keys = [
      {
        name        = "stage-platform"
        description = "Platform services KMS key for stage account"
        policy_sets = ["STAGE_PLATFORM_KMS"]
      }
    ]
  }

  # WAF configuration for stage environment
  wafv2 = {
    enabled = true # Enable for production-like testing
    name    = "stage-waf"
    scope   = "REGIONAL"
  }

  # Account alias for stage account
  iam_account_alias = {
    enabled = true
    alias   = "${local.globals.organization.name}-stage"
  }

  # Stage account specific settings
  account_type          = "workload"
  environment           = "stage"
  is_stage_account      = true
  production_like       = true
  cost_optimization     = false # Disable cost optimization for production-like testing
  enable_spot_instances = false
  enable_fargate_spot   = true
}