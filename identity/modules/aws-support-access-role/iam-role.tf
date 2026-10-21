resource "aws_iam_role" "aws_support" {
  name               = "AWS-Support"
  assume_role_policy = data.aws_iam_policy_document.role_aws_support.json
}

data "aws_iam_policy_document" "role_aws_support" {
  statement {
    sid     = "1"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.aws_support.arn]
    }
  }
}

resource "aws_iam_role_policy_attachment" "aws_support" {
  role       = aws_iam_role.aws_support.name
  policy_arn = "arn:aws:iam::aws:policy/AWSSupportAccess"
}