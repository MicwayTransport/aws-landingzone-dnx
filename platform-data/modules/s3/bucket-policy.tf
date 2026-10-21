# Data source to parse existing custom policy if provided
data "aws_iam_policy_document" "custom_policy" {
  count                   = var.bucket_policy != null ? 1 : 0
  source_policy_documents = [var.bucket_policy]
}

# Data source to generate consolidated bucket policy
data "aws_iam_policy_document" "consolidated_policy" {
  count = var.bucket_policy != null || length(var.allowed_iam_user_names) > 0 || length(var.additional_policy_statements) > 0 || length(var.kms_key_arn) > 0 ? 1 : 0

  # Include custom policy statements if provided
  source_policy_documents = var.bucket_policy != null ? [var.bucket_policy] : []

  # KMS encryption enforcement statements
  dynamic "statement" {
    for_each = length(var.kms_key_arn) > 0 ? [1] : []
    content {
      sid       = "DenyChangingEncryptionType"
      effect    = "Deny"
      resources = ["${aws_s3_bucket.bucket.arn}/*"]
      actions   = ["s3:PutObject"]

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      condition {
        test     = "StringNotEqualsIfExists"
        variable = "s3:x-amz-server-side-encryption"
        values   = ["aws:kms"]
      }

      condition {
        test     = "Null"
        variable = "s3:x-amz-server-side-encryption"
        values   = ["false"]
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.kms_key_arn) > 0 ? [1] : []
    content {
      sid       = "DenyChangingEncryptionKey"
      effect    = "Deny"
      resources = ["${aws_s3_bucket.bucket.arn}/*"]
      actions   = ["s3:PutObject"]

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      condition {
        test     = "StringNotEqualsIfExists"
        variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
        values   = [var.kms_key_arn]
      }

      condition {
        test     = "Null"
        variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
        values   = ["false"]
      }
    }
  }

  # Allow IAM users to list bucket contents
  dynamic "statement" {
    for_each = length(var.allowed_iam_user_names) > 0 ? [1] : []
    content {
      sid    = "AllowIAMUserListBucket"
      effect = "Allow"
      
      principals {
        type        = "AWS"
        identifiers = [
          for user_name in var.allowed_iam_user_names : 
          var.iam_user_module[user_name].user_arn
        ]
      }
      
      actions = [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ]
      
      resources = [aws_s3_bucket.bucket.arn]
    }
  }

  # Allow IAM users to access objects
  dynamic "statement" {
    for_each = length(var.allowed_iam_user_names) > 0 ? [1] : []
    content {
      sid    = "AllowIAMUserObjectAccess"
      effect = "Allow"
      
      principals {
        type        = "AWS"
        identifiers = [
          for user_name in var.allowed_iam_user_names : 
          var.iam_user_module[user_name].user_arn
        ]
      }
      
      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetObjectVersion",
        "s3:DeleteObjectVersion"
      ]
      
      resources = ["${aws_s3_bucket.bucket.arn}/*"]
    }
  }

  # Additional custom statements
  dynamic "statement" {
    for_each = var.additional_policy_statements
    content {
      sid           = try(statement.value.sid, null)
      effect        = try(statement.value.effect, "Allow")
      actions       = try(statement.value.actions, [])
      not_actions   = try(statement.value.not_actions, null)
      resources     = try(statement.value.resources, [])
      not_resources = try(statement.value.not_resources, null)

      dynamic "principals" {
        for_each = try(statement.value.principals, [])
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = try(statement.value.conditions, [])
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

# Single bucket policy resource that handles all scenarios
resource "aws_s3_bucket_policy" "bucket" {
  count  = var.bucket_policy != null || length(var.allowed_iam_user_names) > 0 || length(var.additional_policy_statements) > 0 || length(var.kms_key_arn) > 0 ? 1 : 0
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.consolidated_policy[0].json

  depends_on = [aws_s3_bucket_public_access_block.bucket]
}
