resource "aws_iam_user" "ci_deploy" {
  count = var.create_user ? 1 : 0
  name  = "CIDeploy"
}

resource "aws_iam_user_policy_attachment" "ci_deploy" {
  count      = var.create_user ? 1 : 0
  user       = aws_iam_user.ci_deploy[0].name
  policy_arn = aws_iam_policy.ci_deploy.arn
}
