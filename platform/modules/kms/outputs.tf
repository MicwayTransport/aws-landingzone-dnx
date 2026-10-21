output "kms_keys" {
  description = "A map of the created KMS keys."
  value = {
    for k, v in aws_kms_key.app_key : k => {
      key_arn = v.arn
      key_id  = v.id
    }
  }
}