data "aws_iam_policy_document" "assume_role_ci_deploy_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = var.trust_arns
    }
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ci_deploy_access" {
  name               = "CIDeployAccess"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ci_deploy_access.json
}


output "ci_deploy_access_role_arn" {
  value = aws_iam_role.ci_deploy_access.arn
}
