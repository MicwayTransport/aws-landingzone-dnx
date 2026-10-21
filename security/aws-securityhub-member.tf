resource "aws_securityhub_account" "default" {
  count = try(var.securityhub.enabled, false) && try(var.securityhub.role == "member", false) ? 1 : 0
}

resource "aws_securityhub_invite_accepter" "default" {
  count     = try(var.securityhub.enabled, false) && try(var.securityhub.role == "member", false) ? 1 : 0
  master_id = try(var.securityhub.admin_account_id, "")
  depends_on = [
    aws_securityhub_account.default
  ]
}
