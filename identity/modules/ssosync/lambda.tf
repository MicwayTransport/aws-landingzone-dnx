resource "aws_lambda_function" "lambda" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.iam_for_lambda.arn
  image_uri     = "${aws_ecr_repository.ssosync.repository_url}:${var.lambda_tag}"
  package_type  = "Image"
  timeout       = var.lambda_timeout
  environment {
    variables = {
      SSOSYNC_LOG_LEVEL : var.log_level
      SSOSYNC_LOG_FORMAT : var.log_format
      SSOSYNC_USER_MATCH : var.google_user_match
      SSOSYNC_GROUP_MATCH : var.google_group_match
      SSOSYNC_SYNC_METHOD : var.sync_method
      SSOSYNC_IGNORE_GROUPS : var.ignore_groups
      SSOSYNC_IGNORE_USERS : var.ignore_users
      SSOSYNC_INCLUDE_GROUPS : var.include_groups
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logging,
    aws_iam_role_policy_attachment.lambda_secrets,
    aws_cloudwatch_log_group.ssosync,
    aws_ecr_registry_policy.pull_through,
    aws_ecr_repository.ssosync,
  ]
}

resource "aws_lambda_permission" "default" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}
