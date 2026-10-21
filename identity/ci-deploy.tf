locals {
  ci_deploy_access_trust_arns = concat(
    # [
    #   try(module.ci_deploy[0].ci_deploy_ec2_role_arn, ""),
    #   try(module.ci_deploy[0].ci_deploy_role_arn, ""),
    #   try(module.ci_deploy[0].ci_deploy_user_arn, ""),
    # ],
    ["arn:aws:iam::${var.aws_account_id}:root"],
    formatlist("arn:aws:iam::%s:root", var.ci_deploy_access.trust_account_ids),
    var.ci_deploy_access.trust_arns
  )
}

module "ci_deploy_access" {
  count  = var.ci_deploy_access.enabled ? 1 : 0
  source = "./modules/ci-deploy-access-role"

  trust_arns                  = compact(local.ci_deploy_access_trust_arns)
  custom_policy               = try(var.ci_deploy_access.custom_policy, {})
  policy_sets                 = try(var.ci_deploy_access.policy_sets, ["ECS_DEFAULT"])
  cf_deploy_custom_policy     = try(var.ci_deploy_access.cf_deploy_custom_policy, null)
  ci_deploy_custom_policy     = try(var.ci_deploy_access.ci_deploy_custom_policy, null)
  serverless_app_prefix       = try(var.ci_deploy_access.serverless_app_prefix, "")
  serverless_deploy_role_name = try(var.ci_deploy_access.serverless_deploy_role_name, "CloudFormationDeploy")
}

output "ci_deploy_access_role_arn" {
  value = try(module.ci_deploy_access[0].ci_deploy_access_role_arn, "")
}

output "ci_deploy_access_policies" {
  value = try(module.ci_deploy_access[0].policies, {})
}

# module "ci_deploy" {
#   count  = var.ci_deploy.enabled ? 1 : 0
#   source = "./modules/ci-deploy"

#   create_user             = var.ci_deploy.create_user
#   create_instance_profile = var.ci_deploy.create_instance_profile
#   saml_provider_arn       = local.saml_provider_arn
# }

# output "ci_deploy_ec2_role_arn" {
#   value = try(module.ci_deploy[0].ci_deploy_ec2_role_arn, "")
# }

# output "ci_deploy_instance_profile_arn" {
#   value = try(module.ci_deploy[0].ci_deploy_instance_profile_arn, "")
# }

# output "ci_deploy_role_arn" {
#   value = try(module.ci_deploy[0].ci_deploy_role_arn, "")
# }

# output "ci_deploy_saml_role" {
#   value = try(module.ci_deploy[0].ci_deploy_saml_role, "")
# }

# output "ci_deploy_user_arn" {
#   value = try(module.ci_deploy[0].ci_deploy_user_arn, "")
# }
