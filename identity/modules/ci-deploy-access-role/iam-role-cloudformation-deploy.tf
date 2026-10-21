resource "aws_iam_role" "cloudformation_deploy" {
  name = "CloudFormationDeploy"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = ["cloudformation.amazonaws.com",
        "lambda.amazonaws.com"
        ]
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cf_deploy_policy_set_admin" {
  role       = aws_iam_role.cloudformation_deploy.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "cloudformation_deploy_role_arn" {
  value = aws_iam_role.cloudformation_deploy.arn
}