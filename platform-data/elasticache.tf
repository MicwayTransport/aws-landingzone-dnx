data "aws_kms_key" "redis" {
  for_each = { for redis in try(var.elasticache.redis, []) : redis.name => redis if length(try(redis.kms_name, "")) > 0 }
  key_id   = "alias/${each.value.kms_name}"
}

# Generate secure auth tokens for Redis
resource "random_password" "redis_auth_token" {
  for_each = { for redis in try(var.elasticache.redis, []) : redis.name => redis if try(redis.transit_encryption_enabled, false) }
  length   = 32
  special  = true
  override_special = "!&#$^<>-"
}

# Store auth tokens in Secrets Manager
resource "aws_secretsmanager_secret" "redis_auth_token" {
  for_each = { for redis in try(var.elasticache.redis, []) : redis.name => redis if try(redis.transit_encryption_enabled, false) }
  name     = "/${var.org_name}/${var.account_name}/elasticache/${each.value.name}/auth-token"
  
  tags = merge(
    try(each.value.tags, {}),
    {
      Name        = "${each.value.name}-auth-token"
      Environment = each.value.env
    }
  )
}

resource "aws_secretsmanager_secret_version" "redis_auth_token" {
  for_each      = { for redis in try(var.elasticache.redis, []) : redis.name => redis if try(redis.transit_encryption_enabled, false) }
  secret_id     = aws_secretsmanager_secret.redis_auth_token[each.key].id
  secret_string = random_password.redis_auth_token[each.key].result
}

module "redis" {
  source                                = "git::https://github.com/DNXLabs/terraform-aws-elasticache.git?ref=1.1.1"
  for_each                              = { for redis in try(var.elasticache.redis, []) : redis.name => redis }
  env                                   = each.value.env
  name                                  = each.value.name
  node_type                             = each.value.node_type                    # Required
  number_clusters                       = try(each.value.redis_clusters, 0)       # "Number of Redis cache clusters (NODES) to create"
  multi_az_enabled                      = try(each.value.multi_az_enabled, false) # For "multi_az_enabled" also need to enable "failover_enabled" and update "number_clusters" to at least 2 nodes
  failover_enabled                      = try(each.value.failover, false)
  allowed_cidr                          = [for cidr in try(each.value.allowed_cidr, ["127.0.0.1/32"]) : { cidr = cidr, description = "Allowed CIDR", name = "allowed-cidr" }]
  allow_security_group_ids              = [for sg in try(each.value.allowed_security_groups, []) : { security_group_id = sg, description = "Allowed SG", name = "allowed-sg" }]
  security_group_names                  = try(each.value.security_group_names, [])       # Can't be used with "allow_security_group_ids" (SG_ID with SG_Name)
  vpc_id                                = data.aws_vpc.selected[0].id
  maintenance_window                    = try(each.value.maintenance_window, "") # The format is ddd:hh24:mi-ddd:hh24:mi (24H Clock UTC). The minimum maintenance window is a 60 minute period"
  port                                  = try(each.value.port, 6379)
  snapshot_retention_limit              = try(each.value.snapshot_retention_limit, 0)
  snapshot_window                       = try(each.value.snapshot_window, "06:30-07:30")     # "The daily time range (in UTC) during which ElastiCache will begin taking a daily snapshot of your cache cluster."
  engine_version                        = try(each.value.version, "3.2.10")                  # "Whether to enable encryption in transit. Requires 3.2.6 or >=4.0 engine_version"
  snapshot_arns                         = try(each.value.snapshot_arns, [])                  # "A single-element string list containing an Amazon Resource Name (ARN) of a Redis RDB snapshot file stored in Amazon S3. Example: arn:aws:s3:::my_bucket/snapshot1.rdb"
  snapshot_name                         = try(each.value.snapshot_name, "")                  # " The name of a snapshot from which to restore data into the new node group. Changing the snapshot_name forces a new resource"
  tags                                  = try(each.value.tags, {})
  transit_encryption_enabled            = try(each.value.transit_encryption_enabled, false)
  redis_parameters                      = try(each.value.redis_parameters, [])
  apply_immediately                     = try(each.value.apply_immediately, false) # "Specifies whether any modifications are applied immediately, or during the next maintenance window. Default is false."
  at_rest_encryption_enabled            = try(each.value.at_rest_encryption_enabled, false)
  auth_token                            = try(each.value.transit_encryption_enabled, false) ? random_password.redis_auth_token[each.key].result : null
  auto_minor_version_upgrade            = try(each.value.auto_minor_version_upgrade, false) # "Specifies whether a minor engine upgrades will be applied automatically to the underlying Cache Cluster instances during the maintenance window"
  availability_zones                    = try(each.value.availability_zones, [])
  kms_key_id                            = try(data.aws_kms_key.redis[each.value.name].arn, "")
  notification_topic_arn                = try(each.value.notification_topic_arn, "")
  secret_method                         = try(each.value.secret_method, "ssm")
  user_group_ids                        = try(each.value.user_group_ids, [])
}


resource "random_string" "redis_user_password" {
  for_each = { for user in try(var.elasticache.redis_users.users, []) : user.user_id => user }
  length   = 34
  special  = false
}

resource "aws_elasticache_user" "redis_user" {
  for_each      = { for user in try(var.elasticache.redis_users.users, []) : user.user_id => user }
  user_id       = "${var.account_name}-${each.value.user_id}"
  user_name     = each.value.user_name
  access_string = each.value.access_string
  engine        = "redis"
  passwords     = [random_string.redis_user_password[each.value.user_id].result]
}

resource "aws_elasticache_user_group" "redis_user_group" {
  for_each      = { for group in try(var.elasticache.redis_users.user_groups, []) : group.user_group_id => group }
  engine        = "redis"
  user_group_id = "${var.account_name}-${each.value.user_group_id}"
  user_ids      = [for user_id in try(var.elasticache.redis_users.users, []) : aws_elasticache_user.redis_user[user_id.user_id].user_id]
}

resource "aws_ssm_parameter" "redis_user_password" {
  for_each    = { for user in try(var.elasticache.redis_users.users, []) : user.user_id => user }
  name        = "/${var.account_name}/redis/user/${each.value.user_id}/password"
  description = "Redis user Password for username ${each.value.user_name}"
  type        = "SecureString"
  value       = random_string.redis_user_password[each.value.user_id].result

  lifecycle {
    ignore_changes = [value]
  }
}
