variable "trust_arns" {
  type = list(any)
}

variable "policy_sets" {
  type        = list(string)
  default     = []
  description = "List of policy sets to apply to role. Options: ADMIN, ECS_DEFAULT, SERVERLESS_DEFAULT, SERVERLESS_LIMITED, SERVERLESS_STACK"
}

variable "custom_policy" {
  default = {}
}

variable "serverless_app_prefix" {
  default     = ""
  description = "Prefix of serverless app resources for further restricting policies"
}

variable "serverless_deploy_role_name" {
  default     = "CloudFormationDeploy"
  description = "Name of role used to deploy serverless code (through cloudformation)"
}

variable "cf_deploy_custom_policy" {
  default     = {}
  description = "Custom policy used by a limited role to deploy serverless code (throuh cloudformation)."
}

variable "ci_deploy_custom_policy" {
  default     = {}
  description = "Custom policy used by CIDeployAccess role."
}