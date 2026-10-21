# IRSA (IAM Roles for Service Accounts) Submodule

module "irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "= 5.60.0"

  role_name = var.role_name

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = var.namespace_service_accounts
    }
  }

  # Attach AWS managed policies
  attach_load_balancer_controller_policy = lookup(var.attach_policies, "load_balancer_controller", false)
  attach_external_dns_policy            = lookup(var.attach_policies, "external_dns", false)
  attach_ebs_csi_policy                = lookup(var.attach_policies, "ebs_csi", false)
  attach_efs_csi_policy                = lookup(var.attach_policies, "efs_csi", false)
  attach_vpc_cni_policy                = lookup(var.attach_policies, "vpc_cni", false)
  attach_cluster_autoscaler_policy     = lookup(var.attach_policies, "cluster_autoscaler", false)

  # Custom policy ARNs
  role_policy_arns = {
    for i, arn in var.policy_arns : "policy_${i}" => arn
  }

  tags = var.tags
}
