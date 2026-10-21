# EKS Blueprints Add-ons Integration
# This module adds systematic add-on management to DNX Foundation EKS clusters

# IRSA role for EBS CSI Driver
module "ebs_csi_driver_irsa" {
  count   = local.has_eks_clusters ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name_prefix = "${module.eks[0].cluster_name}-ebs-csi-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks[0].oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

module "eks_blueprints_addons" {
  count = local.has_eks_clusters ? 1 : 0
  
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.23.0"  # Latest stable as of 2026-01-19

  # Cluster information from DNX Foundation EKS module
  cluster_name      = module.eks[0].cluster_name
  cluster_endpoint  = module.eks[0].cluster_endpoint
  cluster_version   = module.eks[0].cluster_version
  oidc_provider_arn = module.eks[0].oidc_provider_arn

  # Wait for cluster to be fully created before deploying add-ons
  depends_on = [module.eks]

  # EKS Native Add-ons (AWS managed)
  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa[0].iam_role_arn
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  # Helm-based Add-ons - Controlled via Terragrunt variables
  enable_aws_load_balancer_controller = try(var.eks_addons.enable_aws_load_balancer_controller, false)
  enable_external_dns                 = try(var.eks_addons.enable_external_dns, false)
  enable_cert_manager                 = try(var.eks_addons.enable_cert_manager, false)
  enable_metrics_server               = try(var.eks_addons.enable_metrics_server, false)
  enable_karpenter                    = try(var.eks_addons.enable_karpenter, false)
  enable_kube_prometheus_stack        = try(var.eks_addons.enable_kube_prometheus_stack, false)
  enable_argocd                       = try(var.eks_addons.enable_argocd, false)
  enable_external_secrets             = try(var.eks_addons.enable_external_secrets, false)

  # AWS Load Balancer Controller configuration
  aws_load_balancer_controller = try(var.eks_addons.aws_load_balancer_controller, {})

  # External DNS configuration
  external_dns = try(var.eks_addons.external_dns, {})
  external_dns_route53_zone_arns = try(
    var.eks_addons.external_dns_route53_zone_arns,
    []
  )

  # Cert Manager configuration
  cert_manager = try(var.eks_addons.cert_manager, {})
  cert_manager_route53_hosted_zone_arns = try(
    var.eks_addons.cert_manager_route53_hosted_zone_arns,
    []
  )

  # Metrics Server configuration
  metrics_server = try(var.eks_addons.metrics_server, {})

  # Karpenter configuration
  karpenter = try(var.eks_addons.karpenter, {})
  karpenter_enable_spot_termination = try(
    var.eks_addons.karpenter_enable_spot_termination,
    true
  )
  karpenter_node = try(var.eks_addons.karpenter_node, {})

  # Kube Prometheus Stack configuration
  kube_prometheus_stack = try(var.eks_addons.kube_prometheus_stack, {})

  # ArgoCD configuration
  argocd = try(var.eks_addons.argocd, {})

  # External Secrets configuration
  external_secrets = try(var.eks_addons.external_secrets, {})
  external_secrets_ssm_parameter_arns = try(
    var.eks_addons.external_secrets_ssm_parameter_arns,
    ["arn:aws:ssm:*:*:parameter/*"]
  )
  external_secrets_secrets_manager_arns = try(
    var.eks_addons.external_secrets_secrets_manager_arns,
    ["arn:aws:secretsmanager:*:*:secret:*"]
  )
  external_secrets_kms_key_arns = try(
    var.eks_addons.external_secrets_kms_key_arns,
    ["arn:aws:kms:*:*:key/*"]
  )

  tags = merge(
    try(var.eks.tags, {}),
    {
      "eks-blueprints-addons" = "enabled"
      "managed-by"            = "terraform"
    }
  )
}
