# MachShip EKS Platform - Scalable Module Implementation
# Uses the reusable EKS module for consistent, configurable deployments

module "eks" {
  count = local.has_eks_clusters ? 1 : 0
  
  source = "./modules/eks"

  # Core Configuration
  cluster_name    = try(var.eks.cluster_name)
  cluster_version = try(var.eks.cluster_version)

  # Network Configuration - DNX Foundation Integration
  vpc_id                   = try(var.eks.vpc_id,data.aws_vpc.selected[0].id)
  subnet_ids               = try(var.eks.subnet_ids,data.aws_subnets.private[0].ids)
  control_plane_subnet_ids = try(var.eks.control_plane_subnet_ids,data.aws_subnets.private[0].ids)

  # Endpoint Configuration
  cluster_endpoint_public_access       = try(var.eks.endpoint_config.public_access, false)
  cluster_endpoint_private_access      = try(var.eks.endpoint_config.private_access, true)
  cluster_endpoint_public_access_cidrs = try(var.eks.endpoint_config.public_access_cidrs, [])

  # Logging Configuration
  cluster_enabled_log_types              = try(var.eks.log_types, ["api", "audit", "authenticator", "controllerManager", "scheduler"])
  cloudwatch_log_group_retention_in_days = try(var.eks.log_retention_days, 7)
  create_cloudwatch_log_group           = try(var.eks.create_cloudwatch_log_group, true)

  # Encryption Configuration - Don't pass cluster_encryption_config, let module use its default
  create_kms_key = try(var.eks.create_kms_key, false)
  kms_key_arn = try(var.eks.kms_key_arn, null)

  # Node Groups Configuration
  eks_managed_node_groups = try(var.eks.node_groups, {})

  # Add-ons Configuration
  # NOTE: EKS native add-ons are now managed by eks-addons.tf (Blueprints module)
  # Only use this for custom add-ons not managed by Blueprints
  cluster_addons = try(var.eks.addons, {})

  # Access Configuration
  authentication_mode                   = try(var.eks.authentication_mode, "API_AND_CONFIG_MAP")
  enable_cluster_creator_admin_permissions = try(var.eks.enable_cluster_creator_admin_permissions, true)

  # Security Group Configuration - Fully Configurable
  create_additional_security_group = try(var.eks.create_additional_security_group, false)
  additional_security_group_description = try(var.eks.additional_security_group_description, "Additional security group for EKS nodes")
  
  # Security group rules - completely user-defined, no defaults
  additional_security_group_ingress_rules = try(var.eks.additional_security_group_ingress_rules, [])
  additional_security_group_egress_rules = try(var.eks.additional_security_group_egress_rules, [])

  # Cluster Security Group Additional Rules
  cluster_security_group_additional_rules = try(var.eks.cluster_security_group_additional_rules, {})
  node_security_group_additional_rules    = try(var.eks.node_security_group_additional_rules, {})

  # IRSA Roles Configuration
  irsa_roles = try(var.eks.irsa_roles, {})

  # Access Entries Configuration - THIS WAS MISSING!
  access_entries = try(var.eks.access_entries, {})

  # Tags - User-defined with intelligent defaults
  tags = merge(
    try(var.eks.tags, {}),
    try(var.eks.additional_tags, {})
  )
}
