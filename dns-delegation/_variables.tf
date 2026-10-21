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

variable "parent_zone_id" {
  description = "Route53 hosted zone ID of the parent zone"
  type        = string
}

variable "parent_zone_name" {
  description = "Domain name of the parent zone (e.g., infra.indyrct.com)"
  type        = string
}

variable "child_zones" {
  description = "Map of child zones to delegate via NS records"
  type = map(object({
    subdomain    = string
    name_servers = list(string)
  }))
  default = {}
}
