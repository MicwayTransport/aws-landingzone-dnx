module "stateful" {
  for_each             = { for instance in try(var.ec2, []) : instance.name => instance }
  source               = "git::https://github.com/DNXLabs/terraform-aws-stateful.git?ref=4.2.0"
  name                 = each.value.name
  instances_subnet_ids = data.aws_subnets.private[0].ids
  vpc_id               = data.aws_vpc.selected[0].id
  instance_type        = try(each.value.instance_type, "")
  ami_id               = try(each.value.ami_id, "")
  sg_cidr_blocks       = try(each.value.sg_cidr_blocks, [])
  certificate_arn      = try(each.value.certificate_arn, "")
  hosted_zone          = try(each.value.hosted_zone, "")
  hostname_create      = try(each.value.hostname_create, false)
  hostnames            = try(each.value.hostnames, [])
  instance_count       = try(each.value.instance_count, 1)
  security_group_ids   = try(each.value.security_group_ids, [])
  userdata             = try(each.value.userdata, "")
  lb_type              = try(each.value.lb_type, "")
}
