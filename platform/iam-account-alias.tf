resource "aws_iam_account_alias" "default" {
  count         = try(var.iam_account_alias, "") != "" ? 1 : 0
  account_alias = try(var.iam_account_alias, var.aws_account_id)
}
