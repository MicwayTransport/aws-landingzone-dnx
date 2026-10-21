
resource "aws_iam_user" "user_dynamic" {
  name               = var.name
}



data "aws_iam_policy_document" "user_dynamic" {

  dynamic "statement" {
    for_each = var.iam_policy.statements

    content {
      sid    = try(statement.value.sid, null)
      effect = try(statement.value.effect, null)

      actions     = try(statement.value.actions, null)
      not_actions = try(statement.value.not_actions, null)

      resources     = try(statement.value.resources, null)
      not_resources = try(statement.value.not_resources, null)

      dynamic "principals" {
        for_each = try(statement.value.principals, [])

        content {
          type        = try(principals.value.type, null)
          identifiers = try(principals.value.identifiers, null)
        }
      }

      dynamic "not_principals" {
        for_each = try(statement.value.not_principals, [])

        content {
          type        = try(not_principals.value.type, null)
          identifiers = try(not_principals.value.identifiers, null)
        }
      }

      dynamic "condition" {
        for_each = try(statement.value.conditions, [])

        content {
          test     = try(condition.value.test, null)
          variable = try(condition.value.variable, null)
          values   = try(condition.value.values, null)
        }
      }
    }
  }

}


resource "aws_iam_policy" "user_dynamic" {
  name = var.name
  policy = data.aws_iam_policy_document.user_dynamic.json
}

resource "aws_iam_user_policy_attachment" "dynamic" {
  user       = aws_iam_user.user_dynamic.name
  policy_arn = aws_iam_policy.user_dynamic.arn
}

