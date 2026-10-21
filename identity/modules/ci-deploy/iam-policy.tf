
data "aws_iam_policy_document" "ci_deploy" {
  statement {
    actions = ["sts:AssumeRole"]
    resources = [
      "arn:aws:iam::*:role/CIDeployAccess"
    ]
  }
  statement {
    actions   = ["ecr:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ci_deploy" {
  name   = "ci-deploy-policy"
  policy = data.aws_iam_policy_document.ci_deploy.json
}
