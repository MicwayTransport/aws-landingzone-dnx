
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}


data "aws_iam_policy_document" "bucket_encrypt_policy" {
  count = length(var.kms_key_arn) > 0 ? 1 : 0

  statement {
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
      values   = [false]
    }
  }

  statement {
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
      values   = [false]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_encrypt_policy" {
  count = length(var.kms_key_arn) > 0 ? 1 : 0

  bucket = aws_s3_bucket.bucket.bucket
  policy = data.aws_iam_policy_document.bucket_encrypt_policy[0].json

  depends_on = [aws_s3_bucket_public_access_block.bucket]
}