# =============================================================================
# STAGE ACCOUNT - PLATFORM DATA STACK
# =============================================================================
# This file configures data platform infrastructure for the stage account.
# The stage account hosts staging environment workloads and pre-production testing.
# 
# STACK PURPOSE: Data services (RDS, ElastiCache, stateful services) for stage workloads
# ACCOUNT: stage (staging and integration testing)
# REGION: ap-southeast-2
# =============================================================================

terraform {
  source = "${get_repo_root()}/platform-data"
}

include "remote_state" {
  path = find_in_parent_folders("remote-state.hcl")
}

# Dependencies - automatically resolved from deployment dependency management
dependencies {
  paths = local.deployment_deps.get_terragrunt_dependencies.stage.platform-data.all_dependencies
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

  # RDS configuration for stage environment
  rds_db = {
    enabled = true
    instances = [
      {
        name                        = "stage-postgres"
        engine                      = "postgres"
        engine_version              = "15.4"
        instance_class              = "db.t3.small" # Production-like instance size
        allocated_storage           = 100
        max_allocated_storage       = 500
        storage_encrypted           = true
        multi_az                    = true # Multi-AZ for production-like testing
        backup_retention_period     = 14
        backup_window               = "03:00-04:00"
        maintenance_window          = "sun:04:00-sun:05:00"
        deletion_protection         = true  # Enable deletion protection
        skip_final_snapshot         = false # Take final snapshot
        database_name               = "stagedb"
        username                    = "stageuser"
        manage_master_user_password = true
      }
    ]
  }

  # ElastiCache configuration for stage environment
  elasticache = {
    enabled = true
    clusters = [
      {
        name                       = "stage-redis"
        engine                     = "redis"
        engine_version             = "7.0"
        node_type                  = "cache.t3.small" # Production-like instance size
        num_cache_nodes            = 2
        port                       = 6379
        parameter_group_name       = "default.redis7"
        subnet_group_name          = "stage-cache-subnet-group"
        security_group_ids         = []
        at_rest_encryption_enabled = true
        transit_encryption_enabled = true
        auth_token_enabled         = true # Enable auth for production-like security
      }
    ]
  }

  # S3 buckets for data storage in stage environment
  bucket = {
    enabled = true
    buckets = [
      {
        name       = "${local.globals.organization.name}-data-stage"
        versioning = true
        encryption = true
        lifecycle_rules = [
          {
            id     = "stage_data_lifecycle"
            status = "Enabled"
            transitions = [
              {
                days          = 30
                storage_class = "STANDARD_IA"
              },
              {
                days          = 90
                storage_class = "GLACIER"
              }
            ]
            expiration = {
              days = 2555 # 7 years retention for production-like testing
            }
          }
        ]
      },
      {
        name       = "${local.globals.organization.name}-backups-stage"
        versioning = true
        encryption = true
        lifecycle_rules = [
          {
            id     = "stage_backup_lifecycle"
            status = "Enabled"
            transitions = [
              {
                days          = 30
                storage_class = "GLACIER"
              }
            ]
            expiration = {
              days = 365 # 1 year backup retention
            }
          }
        ]
      }
    ]
  }

  # DMS configuration for stage environment (if needed)
  dms = {
    enabled               = false # Enable if data migration testing is needed
    replication_instances = []
    endpoints             = []
    replication_tasks     = []
  }

  # AWS MQ configuration for stage environment
  aws_mq = {
    enabled = false # Enable if message queue testing is needed
    brokers = []
  }

  # EC2 database instances for stage environment (if needed)
  ec2_db = {
    enabled   = false # Prefer managed services
    instances = []
  }

  # IAM users for data access in stage environment
  iam_user = {
    enabled = true
    users = [
      {
        name              = "stage-data-user"
        path              = "/stage/"
        policy_sets       = ["STAGE_DATA_ACCESS"]
        create_access_key = true
        pgp_key           = "" # Add PGP key for secure access key delivery
      }
    ]
  }

  # Stage account specific settings
  account_type               = "workload"
  environment                = "stage"
  is_stage_account           = true
  production_like            = true
  cost_optimization          = false
  enable_deletion_protection = true # Enable deletion protection for production-like testing
  backup_retention_days      = 14   # Production-like backup retention
  enable_multi_az            = true # Multi-AZ for production-like testing
}