module "ssosync" {
  count  = try(var.ssosync.enabled, false) ? 1 : 0
  source = "./modules/ssosync"

  enabled = true

  lambda_timeout      = try(var.ssosync.timeout, 300)
  lambda_tag          = try(var.ssosync.tag, "latest")
  schedule_expression = try(var.ssosync.schedule_expression, "rate(24 hours)")
  log_level           = try(var.ssosync.log_level, "warn")
  google_user_match   = try(var.ssosync.google_user_match, "")
  google_group_match  = try(var.ssosync.google_group_match, "")
  sync_method         = try(var.ssosync.sync_method, "groups")
  ignore_groups       = try(var.ssosync.ignore_groups, "")
  ignore_users        = try(var.ssosync.ignore_users, "")
  include_groups      = try(var.ssosync.include_groups, "")
}
