module "log_exporter" {
  count                         = try(var.log_exporter.enabled, false) ? 1 : 0
  source                        = "git::https://github.com/DNXLabs/terraform-aws-log-exporter.git?ref=1.4.0"
  cloudwatch_logs_export_bucket = try(var.log_exporter.cloudwatch_logs_export_bucket, "")
}
