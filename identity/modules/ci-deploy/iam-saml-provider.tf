data "aws_iam_policy_document" "assume_role_saml" {
  count = var.saml_provider_arn != "" ? 1 : 0
  statement {
    principals {
      type        = "Federated"
      identifiers = [var.saml_provider_arn]
    }
    actions = ["sts:AssumeRoleWithSAML"]
    condition {
      test     = "StringEquals"
      variable = "SAML:aud"
      values   = ["https://signin.aws.amazon.com/saml"]
    }
  }
}
