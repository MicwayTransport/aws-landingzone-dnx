output "aws_support_role_arn" {
  value = aws_iam_role.aws_support.arn
}

output "aws_support_user_arn" {
  value = aws_iam_user.aws_support.arn
}