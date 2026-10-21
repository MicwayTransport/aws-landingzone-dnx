resource "aws_ebs_encryption_by_default" "default" {
  count   = try(var.ebs_encryption_by_default.enabled, false) ? 1 : 0
  enabled = true
}
