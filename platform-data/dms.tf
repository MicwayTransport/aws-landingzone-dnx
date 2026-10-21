# module "aws_dms_endpoint" {
#   source   = "git::https://github.com/DNXLabs/terraform-aws-dms-endpoint.git?ref=0.0.3"
#   for_each = { for endpoint in try(local.workspace.dms.endpoint, []) : endpoint.endpoint_id => endpoint }

#   endpoint_id     = each.value.endpoint_id
#   endpoint_type   = each.value.endpoint_type
#   engine_name     = each.value.engine_name
#   kms_key_arn     = try(each.value.kms_key_arn, "")
#   certificate_arn = try(each.value.certificate_arn, "")

#   server_name                 = each.value.server_name
#   database_name               = each.value.database_name
#   username                    = each.value.username
#   password                    = try(data.aws_ssm_parameter.rds[each.value.endpoint_id].value, "")
#   port                        = each.value.port
#   extra_connection_attributes = ""
#   ssl_mode                    = try(each.value.ssl_mode, "none")
#   environment_name            = local.workspace.account_name
# }

# module "aws_dms_replication_task" {
#   source   = "git::https://github.com/DNXLabs/terraform-aws-dms-replication-task.git?ref=0.0.4"
#   for_each = { for task in try(local.workspace.dms.task, []) : task.replication_task_id => task }

#   cdc_start_time            = each.value.cdc_start_time
#   migration_type            = each.value.migration_type
#   replication_instance_arn  = each.value.replication_instance_arn
#   replication_task_id       = each.value.replication_task_id
#   replication_task_settings = data.template_file.read_replication_task_settings[each.value.replication_task_id].rendered
#   source_endpoint_arn       = each.value.source_endpoint_arn
#   target_endpoint_arn       = each.value.target_endpoint_arn
#   table_mappings            = data.template_file.read_table_mappings[each.value.replication_task_id].rendered
#   environment_name          = local.workspace.account_name
# }

# module "aws_dms_instance" {
#   source   = "git::https://github.com/DNXLabs/terraform-aws-dms-replication-instance.git?ref=0.0.2"
#   for_each = { for instance in try(local.workspace.dms.instance, []) : instance.replication_instance_id => instance }

#   allocated_storage            = each.value.allocated_storage
#   availability_zone            = each.value.availability_zone
#   engine_version               = each.value.engine_version
#   preferred_maintenance_window = each.value.preferred_maintenance_window
#   replication_instance_class   = each.value.replication_instance_class
#   replication_instance_id      = each.value.replication_instance_id

#   vpc_security_group_ids = concat(
#     [for cluster_name in try(each.value.ecs_cluster_names, []) : module.ecs_cluster[cluster_name].ecs_nodes_secgrp_id],
#     [for client_vpn_name in try(each.value.allow_from_client_vpns, []) : data.aws_security_groups.rds_client_vpn[client_vpn_name].ids[0]]
#   )

#   replication_subnet_group_id = "dms-replication-subnet-group"
#   subnet_ids                  = data.aws_subnets.private[0].ids
# }

