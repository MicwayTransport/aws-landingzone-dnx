# IRSA Submodule Variables

variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  type        = string
}

variable "namespace_service_accounts" {
  description = "List of namespace:service-account pairs"
  type        = list(string)
}

variable "policy_arns" {
  description = "List of custom policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "attach_policies" {
  description = "Map of AWS managed policies to attach"
  type        = map(bool)
  default     = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
