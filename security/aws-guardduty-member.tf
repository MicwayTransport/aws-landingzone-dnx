
resource "aws_guardduty_invite_accepter" "member" {
  count = try(var.guardduty.enabled, false) && try(var.guardduty.role == "member", false) ? 1 : 0

  detector_id       = aws_guardduty_detector.member[0].id
  master_account_id = try(var.guardduty.admin_account_id, var.aws_account_id)
}

resource "aws_guardduty_detector" "member" {
  count  = try(var.guardduty.enabled, false) && try(var.guardduty.role == "member", false) ? 1 : 0
  enable = true
}
