resource "aws_iam_user" "aws_support" {
  name = "AWS-Support"
}

resource "aws_iam_user_policy_attachment" "aws_support" {
  user       = aws_iam_user.aws_support.name
  policy_arn = aws_iam_policy.aws_support.arn
}
