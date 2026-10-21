output "ci_deploy_ec2_role_arn" {
  value = try(aws_iam_role.ci_deploy_ec2[0].arn, "")
}

output "ci_deploy_instance_profile_arn" {
  value = try(aws_iam_instance_profile.ci_deploy_ec2[0].arn, "")
}

output "ci_deploy_role_arn" {
  value = try(aws_iam_role.ci_deploy[0].arn, "")
}

output "ci_deploy_user_arn" {
  value = try(aws_iam_user.ci_deploy[0].arn, "")
}

output "ci_deploy_saml_role" {
  value = try("${aws_iam_role.ci_deploy[0].arn},${var.saml_provider_arn}", "")
}
