# EKS Module Variables - Fully Configurable and Scalable

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
}

# Network Configuration
variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the cluster"
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "List of subnet IDs for the control plane"
  type        = list(string)
  default     = null
}

# Endpoint Configuration
variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = false
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public endpoint"
  type        = list(string)
  default     = []
}

# Logging Configuration
variable "cluster_enabled_log_types" {
  description = "List of control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 7
}

variable "create_cloudwatch_log_group" {
  description = "Whether to create CloudWatch log group"
  type        = bool
  default     = true
}

# Encryption Configuration - FINAL FIX: Single object as required by terraform-aws-eks
variable "cluster_encryption_config" {
  description = "Configuration block with encryption configuration for the cluster. To disable secret encryption, set this value to `{}`. When create_kms_key is true, only specify resources (provider_key_arn is auto-populated)."
  type        = any
  default = {
    resources = ["secrets"]
  }
}

variable "create_kms_key" {
  description = "Whether to create a KMS key for cluster encryption"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of existing KMS key to use for encryption"
  type        = string
  default     = null
}

variable "kms_key_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 7
}

variable "kms_key_enable_rotation" {
  description = "Enable KMS key rotation"
  type        = bool
  default     = true
}

# Node Groups Configuration
variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions"
  type        = any
  default     = {}
}

# Add-ons Configuration
variable "cluster_addons" {
  description = "Map of cluster addon configurations"
  type        = any
  default     = {}
}

# Access Configuration
variable "authentication_mode" {
  description = "Authentication mode for the cluster"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "access_entries" {
  description = "Map of access entries to add to the cluster"
  type        = any
  default     = {}
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Enable cluster creator admin permissions"
  type        = bool
  default     = true
}

# Security Group Configuration
variable "create_additional_security_group" {
  description = "Whether to create additional security group for nodes"
  type        = bool
  default     = false
}

variable "additional_security_group_description" {
  description = "Description for additional security group"
  type        = string
  default     = "Additional security group for EKS nodes"
}

variable "additional_security_group_ingress_rules" {
  description = "List of ingress rules for additional security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    self        = optional(bool)
  }))
  default = []
}

variable "additional_security_group_egress_rules" {
  description = "List of egress rules for additional security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      description = "All outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# Cluster Security Group Additional Rules
variable "cluster_security_group_additional_rules" {
  description = "List of additional security group rules to add to the cluster security group"
  type        = any
  default     = {}
}

# IRSA Configuration
variable "irsa_roles" {
  description = "Map of IRSA role configurations"
  type = map(object({
    namespace_service_accounts = list(string)
    policy_arns               = list(string)
    attach_policies           = map(bool)
  }))
  default = {}
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "additional_tags" {
  description = "Additional tags to merge with base tags"
  type        = map(string)
  default     = {}
}

variable "node_security_group_additional_rules" {
  description = "Map of additional security group rules to add to the node security group"
  type        = any
  default     = {}
}