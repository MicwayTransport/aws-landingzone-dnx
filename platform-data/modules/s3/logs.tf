resource "aws_s3_bucket_logging" "bucket" {
  count = length(var.log_bucket) > 0 ? 1 : 0

  bucket        = aws_s3_bucket.bucket.id
  target_bucket = var.log_bucket
  target_prefix = "${var.name}/"
}