# Example app without CloudFront

module "ecs_app" {
  for_each = { for app in try(var.ecs.apps, []) : app.name => app }
  source   = "git::https://github.com/DNXLabs/terraform-aws-ecs-app.git?ref=7.5.0"

  depends_on = [module.ecs_cluster]

  name           = each.value.name
  image          = try(each.value.image, "dnxsolutions/nginx-hello:latest")
  container_port = try(each.value.container_port, 80)
  port           = try(each.value.container_port, 80)
  protocol       = try(each.value.container_protocol, "HTTP")
  cpu            = each.value.cpu
  memory         = each.value.memory

  vpc_id                 = data.aws_vpc.selected[0].id
  cluster_name           = module.ecs_cluster[each.value.cluster_name].ecs_name
  alb_arn                = try(each.value.internal, false) ? element(module.ecs_cluster[each.value.cluster_name].alb_internal_arn, 0) : element(module.ecs_cluster[each.value.cluster_name].alb_arn, 0)
  alb_listener_https_arn = try(each.value.internal, false) ? element(module.ecs_cluster[each.value.cluster_name].alb_internal_listener_https_arn, 0) : element(module.ecs_cluster[each.value.cluster_name].alb_listener_https_arn, 0)

  hostnames          = try(each.value.hostnames, [])
  hostname_redirects = try(each.value.hostname_redirects, "")
  hostname_create    = try(each.value.hostname_create, false)
  redirects          = try(each.value.redirects, {})
  alb_only           = try(each.value.alb_only, true) # cluster also need this option to disable ALB WAF
  alb_dns_name       = try(each.value.internal, false) ? element(module.ecs_cluster[each.value.cluster_name].alb_internal_dns_name, 0) : element(module.ecs_cluster[each.value.cluster_name].alb_dns_name, 0)
  # hosted_zone_id          = try(each.value.hosted_zone_id, "")
  hosted_zone             = try(each.value.hosted_zone, "")
  hosted_zone_is_internal = try(each.value.hosted_zone_is_internal, false)
  paths                   = try(each.value.paths, ["/*"])

  healthcheck_path                          = each.value.healthcheck_path
  healthcheck_matcher                       = try(each.value.healthcheck_matcher, 200)
  service_health_check_grace_period_seconds = each.value.service_health_check_grace_period_seconds

  autoscaling_cpu = true
  autoscaling_min = each.value.autoscaling_min
  autoscaling_max = each.value.autoscaling_max

  alarm_high_cpu_usage_above = 60
  alarm_min_healthy_tasks    = 1

  alarm_sns_topics          = try([var.notifications_sns_topic_arn], [])
  cloudwatch_logs_export    = each.value.cloudwatch_logs_export
  cloudwatch_logs_retention = try(each.value.cloudwatch_logs_retention, 7)
  alarm_prefix              = terraform.workspace

  launch_type     = try(each.value.launch_type, "EC2")
  fargate_spot    = try(each.value.fargate_spot, false)
  network_mode    = try(each.value.launch_type, "EC2") == "FARGATE" ? "awsvpc" : null
  security_groups = try(each.value.launch_type, "EC2") == "FARGATE" ? [module.ecs_cluster[each.value.cluster_name].ecs_nodes_secgrp_id] : null
  subnets         = try(each.value.launch_type, "EC2") == "FARGATE" ? data.aws_subnets.private[0].ids : null

  efs_mapping      = try(each.value.efs_mapping_dir, "") != "" ? { module.ecs_cluster[each.value.cluster_name].efs_fs_id : try(each.value.efs_mapping_dir, "") } : {}
  ssm_variables    = try(each.value.ssm_variables, {})
  static_variables = try(each.value.static_variables, {})

  auth_oidc_enabled                = try(each.value.auth_oidc.enabled, false)
  auth_oidc_paths                  = try(each.value.auth_oidc.paths, [])
  auth_oidc_hostnames              = try(each.value.auth_oidc.hostnames, [])
  auth_oidc_authorization_endpoint = try(each.value.auth_oidc.authorization_endpoint, "")
  auth_oidc_client_id              = try(each.value.auth_oidc.client_id, "")
  auth_oidc_client_secret          = try(each.value.auth_oidc.client_secret, "")
  auth_oidc_issuer                 = try(each.value.auth_oidc.issuer, "")
  auth_oidc_token_endpoint         = try(each.value.auth_oidc.token_endpoint, "")
  auth_oidc_user_info_endpoint     = try(each.value.auth_oidc.user_info_endpoint, "")
  auth_oidc_session_timeout        = try(each.value.auth_oidc.session_timeout, 43200)

  task_role_policies_managed = try(each.value.custom_policy.managed, [])
  task_role_policies         = try(each.value.custom_policy.policies, [])

  service_role_arn = length(try(each.value.custom_policy.managed, [])) > 0 || length(try(each.value.custom_policy.policies, [])) > 0 ? null : module.ecs_cluster[each.value.cluster_name].ecs_service_iam_role_arn
  task_role_arn    = length(try(each.value.custom_policy.managed, [])) > 0 || length(try(each.value.custom_policy.policies, [])) > 0 ? null : module.ecs_cluster[each.value.cluster_name].ecs_task_iam_role_arn

  enable_schedule     = try(each.value.shutdown_schedule.enabled, false)
  schedule_cron_start = try(each.value.shutdown_schedule.cron_start, "")
  schedule_cron_stop  = try(each.value.shutdown_schedule.cron_stop, "")
}
