terraform {
  source = "${get_repo_root()}/security"
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
  
  # This is the audit account
  current_account = local.accounts.accounts.audit
}

# Use centralized IAM role
iam_role = local.accounts.iam_roles.audit

dependency "logs" {
  config_path = "${get_repo_root()}/_workspaces/log-archive/ap-southeast-2/logs"
}

inputs = {
  # Use centralized values
  aws_region     = local.globals.default_aws_region
  aws_account_id = local.current_account.account_id
  account_name   = local.current_account.name
  organization = {
    name = local.globals.organization.name
    # Organization members
    # Note: Don't add the security/audit account in the member list
    members = [
      {
        account_id = local.accounts.accounts.root.account_id
        email      = local.accounts.accounts.root.email
      },
      {
        account_id = local.accounts.accounts.log-archive.account_id
        email      = local.accounts.accounts.log-archive.email
      },
      {
        account_id = local.accounts.accounts.backup.account_id
        email      = local.accounts.accounts.backup.email
      },
      {
        account_id = local.accounts.accounts.network-hub.account_id
        email      = local.accounts.accounts.network-hub.email
      },
      {
        account_id = local.accounts.accounts.shared-services.account_id
        email      = local.accounts.accounts.shared-services.email
      },
      {
        account_id = local.accounts.accounts.dev.account_id
        email      = local.accounts.accounts.dev.email
      }
      # 🔄 Add stage, prod, secure-prod here when those accounts are created
    ]
  }

  ## notification 
  chatbot = {
    enabled = false ## it is global resource, only enabled in a single aws_region, use  sns_topic_arns to subscribe other regions SNSs
    slack_targets = [
      {
        slack_channel_name = "aws-alerts"
        slack_channel_id   = "xxxxxxxx"
        slack_workspace_id = "XXXXXXXX" #TH8BC35NJ <- DNX workspace
        logging_level      = "ERROR"
      }
    ]
  }

  notifications = {
    enabled = false # Enable this if you want to use the centralized notification system
    # Email notifications for security events
    email = local.accounts.accounts.audit.email # Use centralized email for security notifications
    # Allow notifications from ALL existing accounts (not just workload accounts)
    # This includes: root, log-archive, backup, network-hub, shared-services, dev
    allow_from_account_ids = [
      local.accounts.accounts.root.account_id,
      local.accounts.accounts.audit.account_id,
      local.accounts.accounts.log-archive.account_id,
      local.accounts.accounts.backup.account_id,
      local.accounts.accounts.network-hub.account_id,
      local.accounts.accounts.shared-services.account_id,
      local.accounts.accounts.dev.account_id
      # 🔄 Add stage, prod, secure-prod here when those accounts are created
    ]
    
  }

  cloudtrail = {
    enabled                     = true                                              # enable when NOT using organization cloudtrail
    role                        = "master"                                          # It creates the KMS key to be used by members
    global                      = true                                              # enable in one region only to avoid duplication of events
    s3_bucket_name              = dependency.logs.outputs.cloudtrail_s3_bucket_name # cloudtrail bucket name - get it from log archive phase 1 output
    log_group_retention_in_days = 365
    alarms = {
      enabled                = false
      mode                   = "full"
      chatbot_aws_account_id = local.current_account.account_id # Use current audit account ID
      slack_channel          = "aws-alerts"
      emails                 = [] # optional
    }
  }

  guardduty = {
    enabled     = true
    role        = "master"
    bucket_name = dependency.logs.outputs.guardduty_s3_bucket_name # Log archive bucket (you need to run log workspace first)
    alarms = {
      enabled                = false
      chatbot_aws_account_id = local.current_account.account_id # Use current audit account ID
      slack_channel          = "aws-alerts"   # thats the sns topic the chatbox is subscring to ?
    }
  }

  securityhub = {
    enabled = true
    role    = "master"
    subscriptions = {
      pci          = false
      cis          = true
      foundational = true
    }
    alarms = {
      enabled                = false          # Enable with caution - very verbose
      chatbot_aws_account_id = local.current_account.account_id # Use current audit account ID
      slack_channel          = "aws-alerts"
      # email: "" # optional
    }
  }

  iam_role_auditor = {
    enabled           = false
    trust_type        = "saml"
    saml_provider_arn = ""
    # or ...
    # trust_type = "iam"
    # iam_principal_arn = "arn:aws:iam::148642451802:root"
  }

  config = {
    enabled        = true
    global         = true # enable in one region only to avoid duplication of events
    role           = "master"
    s3_bucket_name = dependency.logs.outputs.config_s3_bucket_name # config bucket name - get it from log archive phase 1 output
  }

  detective = {
    enabled = false
    role    = "master"
  }

  ebs_encryption_by_default = {
    enabled = true
  }
}
