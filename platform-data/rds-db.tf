data "aws_kms_key" "rds_db" {
  for_each = { for db in try(var.rds.dbs, []) : "${db.name}-${db.environment_name}" => db if length(try(db.kms_name, "")) > 0 }
  key_id   = "alias/${try(each.value.kms_name, "")}"
}

module "rds_db" {
  for_each                    = { for db in try(var.rds.dbs, []) : "${db.name}-${db.environment_name}" => db }
  source                      = "git::https://github.com/DNXLabs/terraform-aws-rds.git?ref=0.16.5"
  db_type                     = try(each.value.db_type, "rds")
  name                        = each.value.name
  environment_name            = each.value.environment_name
  user                        = each.value.user
  retention                   = each.value.retention
  instance_class              = each.value.instance_class
  engine                      = each.value.engine
  engine_version              = try(each.value.engine_version, "")
  port                        = try(each.value.port, 5432)
  multi_az                    = try(each.value.multi_az, false)
  parameter_group_name        = try(each.value.parameter_group_name, null)
  allocated_storage           = try(each.value.allocated_storage, null)
  max_allocated_storage       = try(each.value.max_allocated_storage, 0)
  apply_immediately           = try(each.value.apply_immediately, true)
  snapshot_identifier         = try(each.value.snapshot_identifier, "")
  storage_encrypted           = each.value.storage_encrypted
  kms_key_arn                 = try(data.aws_kms_key.rds_db[each.key].arn, "")
  backup_window               = try(each.value.backup_window, "03:00-03:30")
  backup                      = each.value.backup
  secret_method               = try(each.value.secret_method, "ssm")
  database_name               = try(each.value.database_name, "")
  skip_final_snapshot         = try(each.value.skip_final_snapshot, false)
  storage_type                = try(each.value.storage_type, null)
  iops                        = try(each.value.iops, null)
  db_parameters               = try(each.value.db_parameters, null)
  create_db_parameter_group   = try(each.value.create_db_parameter_group, false)
  parameter_group_description = try(each.value.parameter_group_description, null)
  family                      = try(each.value.family, "")
  allow_cidrs                 = try(each.value.allow_cidrs, [])
  vpc_id                      = data.aws_vpc.selected[0].id
  db_subnet_group_id          = data.aws_db_subnet_group.selected[0].name
  db_subnet_group_replica_id  = data.aws_db_subnet_group.selected[0].name
  auto_minor_version_upgrade  = try(each.value.auto_minor_version_upgrade, true)

  # allow_security_group_ids = concat(
  #   [for cluster_name in try(each.value.ecs_cluster_names, []) : {
  #     security_group_id = try(module.ecs_cluster[cluster_name].ecs_nodes_secgrp_id, null)
  #     description       = "ECS nodes security group for RDS cluster"
  #     name              = cluster_name
  #   }],
  #   [for client_vpn_name in try(each.value.allow_from_client_vpns, []) : {
  #     security_group_id = data.aws_security_groups.rds_client_vpn[client_vpn_name].ids[0]
  #     description       = "RDS client VPN security group"
  #     name              = client_vpn_name
  #   }]
  # )
}

module "rds_scheduler" {
  for_each          = { for db in try(var.rds.dbs, []) : "${db.name}-${db.environment_name}" => db if try(db.shutdown_schedule.enabled, false) }
  source            = "git::https://github.com/DNXLabs/terraform-aws-rds-scheduler.git?ref=1.2.3"
  enable            = each.value.shutdown_schedule.enabled
  identifier        = module.rds_db[each.key].identifier
  cron_stop         = each.value.shutdown_schedule.cron_stop
  cron_start        = each.value.shutdown_schedule.cron_start
  schedule_timezone = try(each.value.shutdown_schedule.timezone, "UTC")
}

# RDS monitoring disabled due to module bug with alarm_sns_topics
# module "rds_monitoring" {
#   for_each         = { for db in try(var.rds.dbs, []) : "${db.name}-${db.environment_name}" => db if try(var.notifications_sns_topic_arn, "") != "" }
#   source           = "git::https://github.com/DNXLabs/terraform-aws-db-monitoring.git?ref=1.4.0"
#   identifier       = module.rds_db[each.key].identifier
#   account_name     = terraform.workspace
#   instance_class   = each.value.instance_class
#   alarm_sns_topics = try(var.notifications_sns_topic_arn, "") != "" ? [var.notifications_sns_topic_arn] : []
# }
