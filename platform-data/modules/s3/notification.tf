resource "aws_s3_bucket_notification" "upload_received" {
  count  = length(var.notification_topic_arn) > 0 ? 1 : 0
  bucket = var.name

  topic {
    topic_arn = var.notification_topic_arn
    events    = var.notification_events
  }
}