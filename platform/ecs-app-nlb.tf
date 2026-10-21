# # Example app without CloudFront
# module "ecs_app_nlb" {
#   for_each = { for app in try(var.ecs.nlb_apps, []) : app.name => app }
#   source   = "git::https://github.com/DNXLabs/terraform-aws-ecs-app-nlb.git?ref=1.12.0"
#   depends_on = [module.ecs_cluster]
#   name           = each.value.name
#   image          = try(each.value.image, "dnxsolutions/nginx-hello:latest")
#   container_port = try(each.value.container_port, 80)
#   port           = try(each.value.container_port, 80)
#   cpu            = each.value.cpu
#   memory         = each.value.memory

#   vpc_id           = data.aws_vpc.selected[0].id
#   cluster_name     = each.value.cluster_name
#   service_role_arn = module.ecs_cluster[each.value.cluster_name].ecs_service_iam_role_arn
#   task_role_arn    = module.ecs_cluster[each.value.cluster_name].ecs_task_iam_role_arn

#   nlb          = try(each.value.create_nlb, true) # Flag to enable NLB
#   nlb_internal = try(each.value.nlb_internal, false)

#   hostname        = try(each.value.hostname, [])
#   hostname_create = try(each.value.hostname_create, false)
#   hosted_zone     = try(each.value.hosted_zone, [])
#   # hosted_zone_is_internal = try(each.value.hosted_zone_is_internal, false) # TODO: To be implemented

#   service_health_check_grace_period_seconds = each.value.service_health_check_grace_period_seconds

#   autoscaling_cpu = true
#   autoscaling_min = each.value.autoscaling_min
#   autoscaling_max = each.value.autoscaling_max

#   alarm_sns_topics = try([var.notifications_sns_topic_arn], [])
#   # cloudwatch_logs_export = each.value.cloudwatch_logs_export # TODO: Add to module
#   alarm_prefix = terraform.workspace # TODO: Add to module

#   launch_type     = try(each.value.launch_type, "EC2")
#   fargate_spot    = try(each.value.fargate_spot, false)
#   network_mode    = try(each.value.launch_type, "EC2") == "FARGATE" ? "awsvpc" : null
#   security_groups = try(each.value.launch_type, "EC2") == "FARGATE" ? [module.ecs_cluster[each.value.cluster_name].ecs_nodes_secgrp_id] : null
#   subnets = (
#     try(each.value.launch_type, "EC2") == "FARGATE" ? (
#       try(each.value.public, false) ? data.aws_subnets.public[0].ids : data.aws_subnets.private[0].ids
#   ) : null)
#   assign_public_ip = try(each.value.launch_type, "EC2") == "FARGATE" ? try(each.value.public, false) : false
# }
