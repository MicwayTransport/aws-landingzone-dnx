output "policies" {
  value = {
    "ECS_DEFAULT" = try(aws_iam_policy.ecs_default[0].arn, "")
    "ECS_ADVANCED" = try(aws_iam_policy.ecs_advanced[0].arn, "")
    "SERVERLESS_DEFAULT" = try(aws_iam_policy.serverless_default[0].arn, "")
    "SERVERLESS_ADVANCED" = try(aws_iam_policy.serverless_advanced[0].arn, "")
    "SERVERLESS_LIMITED" = try(aws_iam_policy.serverless_limited[0].arn, "")
    "SERVERLESS_STACK" = try(aws_iam_policy.serverless_stack[0].arn, "")
    "ADMIN" = "arn:aws:iam::aws:policy/AdministratorAccess"
  }
}