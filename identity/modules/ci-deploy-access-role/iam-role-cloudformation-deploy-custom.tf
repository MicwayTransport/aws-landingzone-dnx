resource "aws_iam_role" "cloudformation_deploy_custom" {
  count = var.cf_deploy_custom_policy != null ? 1 : 0
  name = "${var.serverless_deploy_role_name}Custom"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "cloudformation.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "cloudformation_deploy_custom_policy" {
  count = var.cf_deploy_custom_policy != null ? 1 : 0
  name  = "cloudformation-deploy-custom-policy"
  policy = var.cf_deploy_custom_policy
}

resource "aws_iam_role_policy_attachment" "set_custom_policy" {
  count = var.cf_deploy_custom_policy != null ? 1 : 0
  role       = aws_iam_role.cloudformation_deploy_custom[0].name
  policy_arn = aws_iam_policy.cloudformation_deploy_custom_policy[0].arn
}

output "cloudformation_deploy_custom_role_arn" {
  value = try(aws_iam_role.cloudformation_deploy_custom[0].arn, "")
}