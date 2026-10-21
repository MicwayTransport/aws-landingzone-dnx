resource "aws_iam_role" "ci_deploy" {
  count              = length(data.aws_iam_policy_document.assume_role_saml)
  name               = "CIDeploy"
  assume_role_policy = data.aws_iam_policy_document.assume_role_saml[0].json
}

resource "aws_iam_role_policy_attachment" "ci_deploy" {
  count      = length(data.aws_iam_policy_document.assume_role_saml)
  role       = aws_iam_role.ci_deploy[0].name
  policy_arn = aws_iam_policy.ci_deploy.arn
}
