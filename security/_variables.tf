variable "aws_region" {
  type = string
}

variable "global_tags" {
  description = "Global tags applied to every AWS resource via provider default_tags. Sourced from _workspaces/globals.hcl."
  type        = map(string)
  default     = {}
}

variable "aws_account_id" {
  type = string
}

variable "account_name" {
  type = string
}

variable "cloudtrail" {
  type = any
  default = {
    enabled = false
  }
}

variable "config" {
  type = any
  default = {
    enabled = false
  }
}

variable "detective" {
  type = any
  default = {
    enabled = false
  }
}

variable "securityhub" {
  type = any
  default = {
    enabled = false
  }
}

variable "guardduty" {
  type = any
  default = {
    enabled = false
    alarms = {
      enabled = false
    }
  }
}

variable "notifications" {
  type = any
  default = {
    enabled = false
  }
}

variable "organization" {
  type = any
}

variable "chatbot" {
  type = any
  default = {
    enabled = false
  }
}

variable "log_buckets" {
  type = any
  default = {
    enabled = false
  }
}

variable "iam_role_auditor" {
  type = any
  default = {
    enabled = false
  }
}

variable "ebs_encryption_by_default" {
  type = any
  default = {
    enabled = false
  }
}

variable "kms_cmk" {
  type    = list(any)
  default = []
}
