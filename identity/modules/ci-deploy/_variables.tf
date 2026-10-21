variable "create_user" {
  type    = bool
  default = true
}

variable "create_instance_profile" {
  type    = bool
  default = true
}

variable "saml_provider_arn" {
  description = "SAML Provider ARN to trust the roles created"
  type        = string
}