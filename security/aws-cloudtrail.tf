resource "aws_cloudtrail" "default" {
  count = try(var.cloudtrail.enabled, false) ? 1 : 0

  name                          = "${var.organization.name}-cloudtrail"
  include_global_service_events = try(var.cloudtrail.global, true)
  is_multi_region_trail         = try(var.cloudtrail.global, true)
  enable_log_file_validation    = true

  s3_bucket_name = try(var.cloudtrail.s3_bucket_name, "")
  kms_key_id     = try(var.cloudtrail.kms_key_arn, aws_kms_key.cloudtrail[0].arn)

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_logs[0].arn
}
