# Use the official terraform-aws-eks module from Terraform Registry
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"
  # version = ">= 20.50.0"

  # Core cluster configuration
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Network configuration
  vpc_id                   = var.vpc_id
  subnet_ids              = var.subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids

  # Endpoint configuration
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Security Group Configuration
  cluster_security_group_additional_rules = var.cluster_security_group_additional_rules
  node_security_group_additional_rules    = var.node_security_group_additional_rules
  
  # Logging - Use existing DNX Foundation KMS key
  cluster_enabled_log_types              = var.cluster_enabled_log_types
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id       = var.kms_key_arn

  # Encryption - Don't pass if null, let upstream module use its default
  cluster_encryption_config = var.cluster_encryption_config

  # Node groups
  eks_managed_node_groups = var.eks_managed_node_groups

  # Add-ons - configurable
  cluster_addons = var.cluster_addons

  # Access configuration
  authentication_mode                   = var.authentication_mode
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  access_entries                        = var.access_entries

  # Tags
  tags = var.tags
}

# KMS Key - REMOVED: Using existing DNX Foundation security infrastructure
# KMS key is provided via dependency.security_audit.outputs.cloudtrail_kms_key_arn

# CloudWatch Log Group - REMOVED: terraform-aws-eks module handles this
# The terraform-aws-eks module creates the log group automatically
# No need for duplicate resource creation

# Additional Security Group (configurable)
resource "aws_security_group" "node_additional" {
  count = var.create_additional_security_group ? 1 : 0
  
  name_prefix = "${var.cluster_name}-node-additional-"
  vpc_id      = var.vpc_id
  description = var.additional_security_group_description

  dynamic "ingress" {
    for_each = var.additional_security_group_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      self        = lookup(ingress.value, "self", null)
    }
  }

  dynamic "egress" {
    for_each = var.additional_security_group_egress_rules
    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-node-additional-sg"
  })
}

# IRSA Roles - configurable
module "irsa_roles" {
  source = "./irsa"
  
  for_each = var.irsa_roles

  role_name                = "${var.cluster_name}-${each.key}"
  oidc_provider_arn       = module.eks.oidc_provider_arn
  namespace_service_accounts = each.value.namespace_service_accounts
  policy_arns             = each.value.policy_arns
  attach_policies         = each.value.attach_policies
  
  tags = var.tags
}
