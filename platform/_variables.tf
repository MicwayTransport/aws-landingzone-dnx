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

variable "has_vpc" {
  type    = bool
  default = true
}

variable "notifications_sns_topic_arn" {
  type    = string
  default = ""
}

variable "iam_account_alias" {
  type    = string
  default = ""
}

variable "ec2" {
  type    = list(any)
  default = []
}

variable "ecs" {
  type = any
  default = {
    tasks    = []
    clusters = []
    apps     = []
    workers  = []
  }
}

variable "ecr" {
  type = any
  default = {
    repositories = []
  }
}

variable "wafv2" {
  type    = list(any)
  default = []
}

variable "ssm" {
  type = any
  default = {
    strings         = {}
    secured_strings = []
  }
}

variable "log_exporter" {
  type = any
  default = {
    enabled = false
  }
}

variable "frontend" {
  type = any
  default = {
    apps = []
  }
}

variable "efs" {
  type = any
  default = {
    volumes = []
  }
}

variable "ses" {
  type    = list(any)
  default = []
}

variable "eks" {
  type = any
  default = {
    enabled = false
  }
}

variable "eks_addons" {
  description = "EKS Blueprints add-ons configuration"
  type = any
  default = {
    enabled = false
    
    # Core add-ons (enable flags)
    enable_aws_load_balancer_controller = false
    enable_external_dns                 = false
    enable_cert_manager                 = false
    enable_metrics_server               = false
    enable_karpenter                    = false
    enable_kube_prometheus_stack        = false
    enable_argocd                       = false
    enable_external_secrets             = false
    
    # Add-on specific configurations (optional)
    aws_load_balancer_controller = {}
    external_dns                 = {}
    cert_manager                 = {}
    metrics_server               = {}
    karpenter                    = {}
    kube_prometheus_stack        = {}
    argocd                       = {}
    external_secrets             = {}
    
    # Route53 zones for DNS management
    external_dns_route53_zone_arns        = []
    cert_manager_route53_hosted_zone_arns = []
    
    # Secrets management ARNs
    external_secrets_ssm_parameter_arns      = []
    external_secrets_secrets_manager_arns    = []
    external_secrets_kms_key_arns            = []
    
    # Karpenter specific
    karpenter_enable_spot_termination = true
    karpenter_node                    = {}
  }
}

variable "gitlab_runner" {
  type = any
  default = {
    ci_deploy = {
      enabled = false
    }
  }
}

variable "secrets_manager" {
  type = any
  default = {
    secrets = []
  }
}

variable "ldap" {
  type = any
  default = {}
}

variable "kms_keys" {
  type        = list(any)
  default     = []
  description = "List of KMS keys to create for application use"
}