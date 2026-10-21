
data "aws_iam_policy_document" "aws_support" {
  statement {
    sid     = "1"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWS-Support",
    ]
  }
}

resource "aws_iam_policy" "aws_support" {
  name   = "aws-support-policy"
  policy = data.aws_iam_policy_document.aws_support.json
}
