resource "aws_efs_file_system" "this" {
  for_each = { for volume in try(var.efs.volumes, []) : volume.name => volume }

  encrypted      = true
  creation_token = "${var.account_name}-${each.value.name}"
  tags = {
    Name = each.value.name
  }
}

locals {
  # Create a list of all combinations of volumes and subnets
  volume_subnet_combinations = flatten([
    for volume in try(var.efs.volumes, []) : [
      for subnet_id in data.aws_subnets.private[0].ids : {
        volume_name = volume.name
        ecs_cluster = volume.ecs_cluster
        subnet_id   = subnet_id
      }
    ]
  ])
}

resource "aws_efs_mount_target" "main" {
  # Use for_each over the combinations created above
  for_each = { for combo in local.volume_subnet_combinations : "${combo.volume_name}-${combo.subnet_id}" => combo }

  file_system_id  = aws_efs_file_system.this[each.value.volume_name].id
  subnet_id       = each.value.subnet_id
  security_groups = [module.ecs_cluster[each.value.ecs_cluster].ecs_nodes_secgrp_id]
}
