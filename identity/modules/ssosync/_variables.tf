variable "enabled" {
  type    = bool
  default = false
}

variable "lambda_function_name" {
  type    = string
  default = "ssosync"
}

variable "lambda_timeout" {
  type    = number
  default = 300
}

variable "lambda_image" {
  type = string
  default = "dnxsolutions/ssosync"
}

variable "lambda_tag" {
  type    = string
  default = "latest"
}

variable "aws_google_credentials" {
  type        = string
  description = "Credentials to log into Google (content of credentials.json)"
  default     = null
  sensitive   = true
}

variable "aws_google_admin_email" {
  type        = string
  description = "Google Admin email"
  default     = null
  sensitive   = true
}

variable "aws_scim_endpoint" {
  type        = string
  description = "AWS SSO SCIM Endpoint Url"
  default     = null
  sensitive   = true
}

variable "aws_scim_access_token" {
  type        = string
  description = "AWS SSO SCIM AccessToken"
  default     = null
  sensitive   = true
}

variable "schedule_expression" {
  type        = string
  default     = "rate(24 hours)"
  description = "Schedule for trigger the execution of ssosync (see CloudWatch schedule expressions)"
}

variable "log_level" {
  type        = string
  default     = "warn"
  description = "Log level for Lambda function logging"
  validation {
    condition = contains([
      "panic",
      "fatal",
      "error",
      "warn",
      "info",
      "debug",
      "trace",
    ], var.log_level)
    error_message = "Invalid log_level."
  }
}

variable "log_format" {
  type        = string
  default     = "json"
  description = "Log format for Lambda function logging"
  validation {
    condition = contains([
      "json",
      "text",
    ], var.log_format)
    error_message = "Invalid log_format."
  }
}

variable "google_user_match" {
  type        = string
  description = "Google Workspace user filter query parameter, example: 'name:John* email:admin*', see: https://developers.google.com/admin-sdk/directory/v1/guides/search-users"
  default     = ""
}

variable "google_group_match" {
  type        = string
  description = "Google Workspace group filter query parameter, example: 'name:Admin* email:aws-*', see: https://developers.google.com/admin-sdk/directory/v1/guides/search-groups"
  default     = ""
}

variable "sync_method" {
  type        = string
  default     = "groups"
  description = "Sync method to use"
  validation {
    condition = contains([
      "groups",
      "users_groups",
    ], var.sync_method)
    error_message = "Invalid sync method."
  }
}

variable "ignore_groups" {
  type        = string
  description = "Ignore these Google Workspace groups"
  default     = ""
}

variable "ignore_users" {
  type        = string
  description = "Ignore these Google Workspace users"
  default     = ""
}

variable "include_groups" {
  type        = string
  description = "Include only these Google Workspace groups. (Only applicable for SyncMethod user_groups)"
  default     = ""
}

variable "ecr_prefix" {
  type = string
  default = "ecr-public"
}

variable "ecr_upstream_registry_url" {
  type = string
  default = "public.ecr.aws"
}
