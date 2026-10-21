module "ecs_app_worker" {
  for_each = { for worker in try(var.ecs.workers, []) : worker.name => worker }
  source   = "git::https://github.com/DNXLabs/terraform-aws-ecs-app-worker.git?ref=2.7.0"

  depends_on = [module.ecs_cluster]

  vpc_id        = data.aws_vpc.selected[0].id
  cluster_name  = module.ecs_cluster[each.value.cluster_name].ecs_name
  desired_count = each.value.desired_count
  cpu           = try(each.value.cpu, 256)
  memory        = try(each.value.memory, 512)

  name                                    = each.value.name
  alarm_sns_topics                        = try([var.notifications_sns_topic_arn], [])
  alarm_prefix                            = "${var.org_name}-${var.account_name}"
  cloudwatch_logs_export                  = each.value.cloudwatch_logs_export
  cloudwatch_logs_retention               = try(each.value.cloudwatch_logs_retention, 7)
  log_subscription_filter_enabled         = false
  log_subscription_filter_role_arn        = ""
  log_subscription_filter_destination_arn = ""

  launch_type     = try(each.value.launch_type, "EC2")
  fargate_spot    = try(each.value.fargate_spot, false)
  network_mode    = try(each.value.launch_type, "EC2") == "FARGATE" ? "awsvpc" : null
  security_groups = try(each.value.launch_type, "EC2") == "FARGATE" ? [module.ecs_cluster[each.value.cluster_name].ecs_nodes_secgrp_id] : null
  subnets         = try(each.value.launch_type, "EC2") == "FARGATE" ? data.aws_subnets.private[0].ids : null

  task_role_policies_managed = try(each.value.custom_policy.managed, [])
  task_role_policies         = try(each.value.custom_policy.policies, [])

  autoscaling_cpu = true

  enable_schedule     = try(each.value.shutdown_schedule.enabled, false)
  schedule_cron_start = try(each.value.shutdown_schedule.cron_start, "")
  schedule_cron_stop  = try(each.value.shutdown_schedule.cron_stop, "")
}


output "ecs_app_worker" {
  value = element(module.ecs_app_worker[*], 0)
}
