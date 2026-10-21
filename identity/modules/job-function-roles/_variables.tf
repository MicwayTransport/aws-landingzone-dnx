
variable "role_max_session_duration" {
  description = "Maximum CLI/API session duration"
  default     = "43200"
}

variable "saml_provider_arn" {
  description = "SAML Provider ARN to trust the roles created (pass either a name or ARN)"
  default     = ""
}

variable "create_default_roles" {
  description = "Create default roles in the account"
  default     = true
}


