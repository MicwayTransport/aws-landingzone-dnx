data "aws_kms_key" "s3" {
  for_each = { for bucket in try(var.buckets, []) : bucket.name => bucket if try(bucket.kms_name, null) != null }
  key_id   = "alias/${try(each.value.kms_name, "")}"
}
module "s3" {
  for_each = { for bucket in try(var.buckets, []) : bucket.name => bucket }
  source   = "./modules/s3"

  name                   = each.value.name
  environment            = try(each.value.environment, "default")
  kms_key_arn            = try(data.aws_kms_key.s3[each.key].arn, each.value.kms_key_arn, "")
  sse_algorithm          = try(each.value.sse_algorithm, "AES256")
  notification_topic_arn = try(each.value.notification.topic_arn, "")
  notification_events    = try(each.value.notification.events, ["s3:ObjectCreated:*"])
  versioning             = try(each.value.versioning, false)
  mfa_delete             = try(each.value.mfa_delete, false)
  lifecycle_rules        = try(each.value.lifecycle_rules, [])
  log_bucket             = try(each.value.log_bucket, false) ? "bemoved-log-archives-s3-access-logs-${var.aws_region}" : ""
}
