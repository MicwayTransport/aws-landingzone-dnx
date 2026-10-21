# Platform Stack Outputs - Consolidated and Clean

# =============================================================================
# EKS OUTPUTS (Conditional - only when EKS is enabled)
# =============================================================================

output "eks_cluster_info" {
  description = "Comprehensive EKS cluster information"
  value = local.has_eks_clusters ? {
    cluster_id       = module.eks[0].cluster_id
    cluster_arn      = module.eks[0].cluster_arn
    cluster_name     = module.eks[0].cluster_name
    cluster_endpoint = module.eks[0].cluster_endpoint
    cluster_version  = module.eks[0].cluster_version
    cluster_status   = module.eks[0].cluster_status
    
    # Security and Authentication
    oidc_provider_arn = module.eks[0].oidc_provider_arn
    oidc_issuer_url   = module.eks[0].cluster_oidc_issuer_url
    
    # Security Groups
    cluster_security_group_id         = module.eks[0].cluster_security_group_id
    cluster_primary_security_group_id = module.eks[0].cluster_primary_security_group_id
    node_security_group_id           = module.eks[0].node_security_group_id
    additional_security_group_id     = module.eks[0].additional_security_group_id
    
    # IRSA Role ARNs
    irsa_role_arns = module.eks[0].irsa_role_arns
    
    # Infrastructure
    kms_key_arn               = module.eks[0].kms_key_arn
    cloudwatch_log_group_name = module.eks[0].cloudwatch_log_group_name
    
    # Integration Information
    vpc_id             = data.aws_vpc.selected[0].id
    vpc_cidr_block     = data.aws_vpc.selected[0].cidr_block
    private_subnet_ids = data.aws_subnets.private[0].ids
    public_subnet_ids  = data.aws_subnets.public[0].ids
  } : null
  
  sensitive = true
}

output "eks_kubeconfig_command" {
  description = "Command to update kubeconfig for the EKS cluster"
  value       = local.has_eks_clusters ? "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks[0].cluster_name}" : null
}

# Individual EKS outputs for backward compatibility
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = local.has_eks_clusters ? module.eks[0].cluster_name : null
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = local.has_eks_clusters ? module.eks[0].cluster_endpoint : null
}

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = local.has_eks_clusters ? module.eks[0].oidc_provider_arn : null
}

output "eks_cluster_version" {
  description = "Version of the EKS cluster"
  value       = local.has_eks_clusters ? module.eks[0].cluster_version : null
}

# =============================================================================
# EKS BLUEPRINTS ADD-ONS OUTPUTS
# =============================================================================

output "eks_addons_info" {
  description = "EKS Blueprints add-ons information"
  value = local.has_eks_clusters ? {
    # EKS native add-ons
    eks_addons = try(module.eks_blueprints_addons[0].eks_addons, {})
    
    # Helm-based add-ons
    argocd                       = try(module.eks_blueprints_addons[0].argocd, {})
    aws_load_balancer_controller = try(module.eks_blueprints_addons[0].aws_load_balancer_controller, {})
    external_dns                 = try(module.eks_blueprints_addons[0].external_dns, {})
    cert_manager                 = try(module.eks_blueprints_addons[0].cert_manager, {})
    metrics_server               = try(module.eks_blueprints_addons[0].metrics_server, {})
    karpenter                    = try(module.eks_blueprints_addons[0].karpenter, {})
    kube_prometheus_stack        = try(module.eks_blueprints_addons[0].kube_prometheus_stack, {})
    external_secrets             = try(module.eks_blueprints_addons[0].external_secrets, {})
    
    # GitOps metadata
    gitops_metadata = try(module.eks_blueprints_addons[0].gitops_metadata, {})
  } : null
  
  sensitive = true
}

# =============================================================================
# ECS OUTPUTS (Existing - maintain compatibility)
# =============================================================================

# Add existing ECS outputs here if they exist in other files
# This ensures all platform outputs are in one place

# =============================================================================
# NETWORK INTEGRATION OUTPUTS
# =============================================================================

output "vpc_info" {
  description = "VPC information for integration"
  value = local.has_vpc ? {
    vpc_id             = data.aws_vpc.selected[0].id
    vpc_cidr_block     = data.aws_vpc.selected[0].cidr_block
    private_subnet_ids = data.aws_subnets.private[0].ids
    public_subnet_ids  = data.aws_subnets.public[0].ids
    secure_subnet_ids  = data.aws_subnets.secure[0].ids
  } : null
}

# =============================================================================
# PLATFORM STACK SUMMARY
# =============================================================================

output "platform_stack_summary" {
  description = "Summary of deployed platform components"
  value = {
    stack_name        = local.stack_name
    account_name      = var.account_name
    aws_region        = var.aws_region
    
    # Component status
    has_vpc           = local.has_vpc
    has_eks_clusters  = local.has_eks_clusters
    has_ecs_clusters  = local.has_ecs_clusters
    
    # Deployment timestamp
    deployed_at       = timestamp()
  }
}
