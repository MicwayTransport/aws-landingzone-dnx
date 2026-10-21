module "cloudtrail_custom_alarms" {
  count                        = (try(var.cloudtrail.enabled, false) && try(var.cloudtrail.alarms.enabled, false)) ? 1 : 0
  source                       = "git::https://github.com/DNXLabs/terraform-aws-cloudtrail-notification.git?ref=4.0.0"
  cloudtrail_log_group_name    = try(aws_cloudwatch_log_group.cloudtrail[0].name, "")
  alarm_mode                   = try(var.cloudtrail.alarms.mode, "light")
  alarm_notification_sns_topic = try(module.notifications[0].sns_topic_arn, "")
  kms_key                      = try(var.cloudtrail.kms_key_arn, aws_kms_key.cloudtrail[0].arn)
  lambda_timeout               = 5
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  count             = try(var.cloudtrail.enabled, false) ? 1 : 0
  name              = "/aws/cloudtrail/${var.account_name}"
  kms_key_id        = try(var.cloudtrail.kms_key_arn, aws_kms_key.cloudtrail[0].arn)
  retention_in_days = try(var.cloudtrail.log_group_retention_in_days, 365)
}

resource "aws_iam_role" "cloudtrail_logs" {
  count       = try(var.cloudtrail.enabled, false) ? 1 : 0
  name_prefix = "CloudtrailLogsServiceRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch" {
  count       = try(var.cloudtrail.enabled, false) ? 1 : 0
  name_prefix = "cloudwatch_"
  role        = aws_iam_role.cloudtrail_logs[0].id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailPutLogEvents20141101",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}


