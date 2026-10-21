# EKS Module Outputs

# Cluster Information
output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = module.eks.cluster_version
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = module.eks.cluster_status
}

# Security and Authentication
output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if enabled"
  value       = module.eks.oidc_provider_arn
}

# Node Groups
output "eks_managed_node_groups" {
  description = "Map of attribute maps for all EKS managed node groups created"
  value       = module.eks.eks_managed_node_groups
  sensitive   = true
}

output "eks_managed_node_groups_autoscaling_group_names" {
  description = "List of the autoscaling group names created by EKS managed node groups"
  value       = module.eks.eks_managed_node_groups_autoscaling_group_names
}

# Security Groups
output "cluster_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = module.eks.cluster_primary_security_group_id
}

output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = module.eks.node_security_group_id
}

output "additional_security_group_id" {
  description = "ID of the additional security group created for node groups"
  value       = var.create_additional_security_group ? aws_security_group.node_additional[0].id : null
}

# Add-ons
output "cluster_addons" {
  description = "Map of attribute maps for all EKS cluster addons enabled"
  value       = module.eks.cluster_addons
}

# IRSA Role ARNs
output "irsa_role_arns" {
  description = "Map of IRSA role ARNs"
  value       = { for k, v in module.irsa_roles : k => v.iam_role_arn }
}

# KMS - Using existing security infrastructure
output "kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the KMS key used for cluster encryption"
  value       = var.kms_key_arn  # Using existing security infrastructure KMS key
}

output "kms_key_id" {
  description = "The globally unique identifier for the KMS key used for cluster encryption"
  value       = null  # Not applicable when using existing KMS key
}

# CloudWatch - Using terraform-aws-eks module outputs
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for cluster logs"
  value       = module.eks.cloudwatch_log_group_name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for cluster logs"
  value       = module.eks.cloudwatch_log_group_arn
}

output "debug_node_rules_passthrough" {
  description = "DEBUG: Shows the value of node_security_group_additional_rules passed to the module."
  value       = var.node_security_group_additional_rules
}