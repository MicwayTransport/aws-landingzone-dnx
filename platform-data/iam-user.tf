# IAM Users for platform-data access
# Inlined from identity/modules/iam-user to avoid cross-stack module reference issues

resource "aws_iam_user" "user" {
  for_each = { for user in try(var.iam_users, []) : user.name => user }
  name     = each.value.name
}

data "aws_iam_policy_document" "user" {
  for_each = { for user in try(var.iam_users, []) : user.name => user }

  dynamic "statement" {
    for_each = each.value.iam_policy.statements

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

resource "aws_iam_policy" "user" {
  for_each = { for user in try(var.iam_users, []) : user.name => user }
  name     = each.value.name
  policy   = data.aws_iam_policy_document.user[each.key].json
}

resource "aws_iam_user_policy_attachment" "user" {
  for_each   = { for user in try(var.iam_users, []) : user.name => user }
  user       = aws_iam_user.user[each.key].name
  policy_arn = aws_iam_policy.user[each.key].arn
}

# EXTERNAL KEY MANAGEMENT APPROACH
# Access keys are NOT created by Terraform to avoid storing them in state
# Keys must be created externally and stored in Secrets Manager manually

# Create placeholder secrets for external key management
# This allows Terraform to manage the secret metadata while keys are managed externally
resource "aws_secretsmanager_secret" "external_key_placeholder" {
  for_each                = { for user in try(var.iam_users, []) : user.name => user if try(user.use_external_keys, false) }
  name                    = "${each.value.name}-access-keys"
  description             = "Access keys for IAM user ${each.value.name} (managed externally)"
  recovery_window_in_days = 7

  tags = {
    Name        = "${each.value.name}-access-keys"
    Environment = var.account_name
    Purpose     = "IAM Access Keys"
    Sensitive   = "true"
    Management  = "External"
  }

  lifecycle {
    # Prevent Terraform from managing the secret value - only metadata
    ignore_changes = [
      description,
      tags
    ]
  }
}

# Data source to reference the secret after it's created (for outputs)
# This will only be used after the secret exists
data "aws_secretsmanager_secret" "external_user_keys" {
  for_each   = aws_secretsmanager_secret.external_key_placeholder
  name       = each.value.name
  depends_on = [aws_secretsmanager_secret.external_key_placeholder]
}
