variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "global_tags" {
  description = "Global tags applied to every AWS resource via provider default_tags. Sourced from _workspaces/globals.hcl."
  type        = map(string)
  default     = {}
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "account_name" {
  description = "Account name"
  type        = string
}

variable "org_name" {
  description = "Organization name"
  type        = string
}

variable "account_type" {
  description = "Account type (workload or backup)"
  type        = string
  validation {
    condition     = contains(["workload", "backup"], var.account_type)
    error_message = "Account type must be either 'workload' or 'backup'."
  }
}

variable "backup" {
  description = "Backup configuration"
  type = list(object({
    name                                  = string
    enabled                               = bool
    kms_name                              = optional(string)
    selection_tag_key                     = optional(string, "Backup")
    selection_tag_value                   = optional(string, "true")
    rds                                   = optional(list(string), [])
    min_retention_days                    = optional(number)
    max_retention_days                    = optional(number)
    enable_aws_backup_vault_notifications = optional(bool, false)
    backup_vault_events                   = optional(list(string), ["BACKUP_JOB_FAILED", "COPY_JOB_FAILED"])
    notification_slack_endpoint           = optional(string, "")
    notification_email                    = optional(string, "")
    allow_from_account_ids                = optional(list(string), [])
    rules = optional(list(object({
      rule_name                = string
      enable_continuous_backup = optional(bool, false)
      schedule                 = string
      start_window             = optional(number, 60)
      completion_window        = optional(number, 120)
      lifecycle = optional(object({
        cold_storage_after = optional(number)
        delete_after       = optional(number, 30)
      }))
      copy_actions = optional(list(object({
        destination_vault_arn = string
        lifecycle = optional(object({
          cold_storage_after = optional(number)
          delete_after       = optional(number)
        }))
      })), [])
    })), [])
    copy_action = optional(object({
      aws_account_id = string
    })),
  }))
  default = []
}

variable "notifications" {
  description = "Notification configuration"
  type = object({
    enabled        = optional(bool, false)
    slack_endpoint = optional(string, "")
    email          = optional(string, "")
    account_ids    = optional(list(string), [])
  })
  default = {
    enabled = false
  }
}

variable "notifications_sns_topic_arn" {
  description = "External SNS topic ARN for notifications"
  type        = string
  default     = ""
}