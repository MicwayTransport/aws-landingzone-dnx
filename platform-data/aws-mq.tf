resource "random_string" "mq_broker_password" {
  for_each = { for broker in try(var.mq.brokers, []) : broker.name => broker }
  length   = 34
  special  = false
}

resource "aws_security_group" "mq_broker" {
  for_each = { for broker in try(var.mq.brokers, []) : broker.name => broker }

  name        = "${each.value.name}-sg"
  description = "Allow broker ${each.value.name} inbound traffic"
  vpc_id      = data.aws_vpc.selected[0].id

  ingress {
    from_port   = 8162
    to_port     = 8162
    protocol    = "tcp"
    cidr_blocks = [try(each.value.allow_cidr_blocks, "0.0.0.0/0")]
  }
  ingress {
    from_port   = 61614
    to_port     = 61614
    protocol    = "tcp"
    cidr_blocks = [try(each.value.allow_cidr_blocks, "0.0.0.0/0")]
  }
}

resource "aws_secretsmanager_secret" "mq_broker" {
  for_each = { for broker in try(var.mq.brokers, []) : broker.name => broker }

  name                    = "/mq/broker/${each.value.name}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "mq_broker" {
  for_each      = { for broker in try(var.mq.brokers, []) : broker.name => broker }
  secret_id     = aws_secretsmanager_secret.mq_broker[each.value.name].id
  secret_string = random_string.mq_broker_password[each.key].result
}

data "aws_kms_key" "mq_broker" {
  for_each = { for broker in try(var.mq.brokers, []) : broker.name => broker if broker.kms_name != "" }
  key_id   = "alias/${try(each.value.kms_name, "")}"
}

resource "aws_mq_broker" "mq_broker" {
  for_each = { for broker in try(var.mq.brokers, []) : broker.name => broker }

  broker_name                = each.value.name
  publicly_accessible        = try(each.value.publicly_accessible, false)
  auto_minor_version_upgrade = try(each.value.auto_minor_version_upgrade, true)

  deployment_mode = try(each.value.deployment_mode, "SINGLE_INSTANCE")
  encryption_options {
    kms_key_id        = try(data.aws_kms_key.mq_broker[each.value.name].arn, "")
    use_aws_owned_key = length(each.value.kms_name) > 0 ? false : true
  }

  ## generate automatically,  in case different setting use aws_mq_configuration resource 
  ## https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/mq_configuration

  #   configuration { 
  #     id       = aws_mq_configuration.test.id
  #     revision = aws_mq_configuration.test.latest_revision
  #   }

  engine_type        = try(each.value.type, "ActiveMQ")
  engine_version     = try(each.value.version, "5.17.6")
  host_instance_type = try(each.value.instance_type, "mq.t2.micro")
  security_groups    = [aws_security_group.mq_broker[each.value.name].id]
  subnet_ids         = try(each.value.deployment_mode, "SINGLE_INSTANCE") == "SINGLE_INSTANCE" ? [data.aws_subnets.private[0].ids[0]] : [data.aws_subnets.private[0].ids[0], data.aws_subnets.private[0].ids[1]]

  user {
    username = try(each.value.username, "fm")
    password = random_string.mq_broker_password[each.key].result
  }
}
