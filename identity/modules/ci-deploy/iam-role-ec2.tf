data "aws_iam_policy_document" "assume_role_ci_deploy_ec2" {
  count = var.create_instance_profile ? 1 : 0
  statement {
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ci_deploy_ec2" {
  count              = var.create_instance_profile ? 1 : 0
  name               = "CIDeployEc2"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ci_deploy_ec2[0].json
}

resource "aws_iam_instance_profile" "ci_deploy_ec2" {
  count = var.create_instance_profile ? 1 : 0
  name  = "CIDeployInstanceProfile"
  role  = aws_iam_role.ci_deploy_ec2[0].name
}

resource "aws_iam_role_policy_attachment" "ci_deploy_ec2" {
  count      = var.create_instance_profile ? 1 : 0
  role       = aws_iam_role.ci_deploy_ec2[0].name
  policy_arn = aws_iam_policy.ci_deploy.arn
}
