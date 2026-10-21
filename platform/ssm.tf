resource "aws_ssm_parameter" "ssm_parameter_strings" {
  for_each    = try(var.ssm.strings, {})
  name        = each.key
  description = each.key
  type        = "String"
  value       = each.value
  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_ssm_parameter" "ssm_parameter_secure_strings" {
  for_each    = { for key in try(var.ssm.secured_strings, []) : key.name => key }
  name        = each.value.name
  description = each.value.name
  type        = "SecureString"
  value       = "NO_VALUE"
  key_id      = try(var.ssm.kms_key_arn, "") != "" ? var.ssm.kms_key_arn : "alias/aws/ssm"
  lifecycle {
    ignore_changes = [value, insecure_value]
  }
}
