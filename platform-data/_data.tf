# data "template_file" "read_replication_task_settings" {
#   for_each = { for replication_task_settings in try(var.dms.task, []) : replication_task_settings.replication_task_id => replication_task_settings }
#   template = file("dms_files/${each.value.replication_task_settings}")
# }

# data "template_file" "read_table_mappings" {
#   for_each = { for table_mappings in try(var.dms.task, []) : table_mappings.replication_task_id => table_mappings }
#   template = file("dms_files/${each.value.table_mappings}")
# }

data "aws_vpc" "selected" {
  count = var.has_vpc ? 1 : 0
  filter {
    name   = "tag:EnvName"
    values = [var.account_name]
  }
}

data "aws_subnets" "private" {
  count = var.has_vpc ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected[0].id]
  }

  filter {
    name   = "tag:Scheme"
    values = ["private"]
  }
}

data "aws_cloudformation_export" "network_db_subnet_group" {
  count = length(try(var.rds.dbs, [])) > 0 ? 1 : 0
  name  = "TfExport-Network-${var.account_name}-DbSubnetGroupId"
}

data "aws_db_subnet_group" "selected" {
  count = length(try(var.rds.dbs, [])) > 0 ? 1 : 0
  name  = data.aws_cloudformation_export.network_db_subnet_group[0].value
}

data "aws_ssm_parameter" "rds" {
  for_each = { for ssm in try(var.dms.endpoint, []) : ssm.endpoint_id => ssm }
  name     = each.value.ssm
}

data "aws_security_groups" "rds_client_vpn" {
  for_each = toset(flatten(try(var.rds.dbs[*].allow_from_client_vpns, [])))
  filter {
    name   = "tag:EnvName"
    values = [each.key]
  }
}
