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

variable "org_name" {
  type = string
}

variable "acm" {
  type = any
  default = {
    certificates = []
  }
}

variable "domain" {
  type = any
  default = {
    enabled = false
    zones   = []
  }
}

variable "route53_resolver" {
  type = any
  default = {
    outbound_rules = {
      domains = []
    }
  }
}

variable "vpn" {
  type = any
  default = {
    enabled = false
  }
}

variable "openvpn" {
  type = any
  default = {
    enabled = false
  }
}

variable "network" {
  type = any
  default = {
    enabled = false
  }
}

variable "site_to_site_vpn" {
  type = any
  default = {
    enabled = false
  }
}

variable "transit_gateway" {
  type = any
  default = {
    enabled = false
    attachment = {
      enabled = false
    }
  }
}
