resource "aws_cloudwatch_log_group" "ssosync" {
  name = "/aws/lambda/${var.lambda_function_name}"
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name_prefix         = "ssosync-schedule"
  description         = "Frequency to synchronize AWS SSO with GSuite"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda_schedule" {
  rule = aws_cloudwatch_event_rule.schedule.name
  arn  = aws_lambda_function.lambda.arn
}
