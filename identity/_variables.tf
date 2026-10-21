variable "aws_region" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "account_name" {
  type = string
}

variable "org_name" {
  type = string
}

variable "job_function_roles" {
  type = any
  default = {
    enabled = false
  }
}

variable "ci_deploy" {
  type = any
  default = {
    enabled = false
  }
}

variable "ci_deploy_access" {
  type = any
  default = {
    enabled = false
  }
}

variable "saml_provider" {
  type = any
  default = {
    get_from_baseline_cf_stack = false
  }
}

variable "baseline_cf_stack_name" {
  type    = string
  default = "identity-baseline"
}

variable "iam_password_policy" {
  type = any
  default = {
    enabled = false
  }
}

variable "aws_support_role" {
  type = any
  default = {
    enabled = false
  }
}

variable "oidc" {
  type = any
  default = {
    enabled = false
  }
}

variable "ssosync" {
  type = any
  default = {
    enabled = false
  }
}

variable "iam_users" {
  type    = list(any)
  default = []
}
