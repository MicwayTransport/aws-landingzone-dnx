resource "aws_iam_account_password_policy" "strict" {
  count                        = var.iam_password_policy.enabled ? 1 : 0
  minimum_password_length      = 14
  password_reuse_prevention    = 24
  require_lowercase_characters = true
  require_numbers              = true
  require_uppercase_characters = true
  require_symbols              = true
  max_password_age             = 80
}
