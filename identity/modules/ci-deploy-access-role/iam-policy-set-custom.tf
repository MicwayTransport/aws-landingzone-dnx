resource "aws_iam_policy" "ci_deploy_custom_policy" {
  count = var.ci_deploy_custom_policy != null ? 1 : 0
  name  = "CIDeployAccess-custom-policy"
  policy = var.ci_deploy_custom_policy
}

resource "aws_iam_role_policy_attachment" "ci_deploy_custom_policy" {
  count = var.ci_deploy_custom_policy != null ? 1 : 0
  role       = aws_iam_role.ci_deploy_access.name
  policy_arn = aws_iam_policy.ci_deploy_custom_policy[0].arn
}