module "stateful" {
  for_each = { for instance in try(var.ec2, []) : instance.name => instance }
  source   = "git::https://github.com/DNXLabs/terraform-aws-stateful.git?ref=4.2.0"
  
  # Basic configuration
  name                 = each.value.name
  instances_subnet_ids = data.aws_subnets.private[0].ids
  vpc_id               = data.aws_vpc.selected[0].id
  instance_type        = try(each.value.instance_type, "t3.medium")
  ami_id               = try(each.value.ami_id, "")
  instance_count       = try(each.value.instance_count, 1)
  
  # Enhanced deployment options
  autoscaling_enabled    = try(each.value.autoscaling_enabled, false)
  load_balancer_enabled  = try(each.value.load_balancer_enabled, false)
  
  # Autoscaling configuration
  autoscaling_config = try(each.value.autoscaling_config, {
    min_size                   = 1
    max_size                   = 1
    desired_capacity          = 1
    health_check_type         = "EC2"
    health_check_grace_period = 300
    protect_from_scale_in     = false
  })
  
  # Instance-specific configuration (for standalone instances)
  instances_config = try(each.value.instances_config, [])
  
  # Secondary IP configuration
  secondary_ip_count = try(each.value.secondary_ip_count, 0)
  
  # Enhanced features
  enable_termination_protection = try(each.value.enable_termination_protection, false)
  enable_ebs_optimization      = try(each.value.enable_ebs_optimization, false)
  enable_detailed_monitoring   = try(each.value.enable_detailed_monitoring, false)
  
  # Storage configuration
  root_volume_size       = try(each.value.root_volume_size, 50)
  root_volume_type       = try(each.value.root_volume_type, "gp3")
  root_volume_iops       = try(each.value.root_volume_iops, 3000)
  root_volume_throughput = try(each.value.root_volume_throughput, 125)
  
  data_volume_enabled    = try(each.value.data_volume_enabled, false)
  data_volume_size       = try(each.value.data_volume_size, 100)
  data_volume_type       = try(each.value.data_volume_type, "gp3")
  data_volume_iops       = try(each.value.data_volume_iops, 3000)
  data_volume_throughput = try(each.value.data_volume_throughput, 125)
  data_volume_device_name = try(each.value.data_volume_device_name, "/dev/sdf")
  
  delete_volumes_on_termination = try(each.value.delete_volumes_on_termination, false)
  
  # EBS encryption
  ebs_encrypted   = try(each.value.ebs_encrypted, true)
  ebs_kms_key_id = try(each.value.ebs_kms_key_id, "")
  
  # Load balancer configuration
  lb_type         = try(each.value.lb_type, "")
  lb_scheme       = try(each.value.lb_scheme, "internal")
  lb_subnet_ids   = try(each.value.lb_subnet_ids, [])
  certificate_arn = try(each.value.certificate_arn, "")
  tcp_ports       = try(each.value.tcp_ports, [])
  udp_ports       = try(each.value.udp_ports, [])
  http_port       = try(each.value.http_port, 80)
  
  # Security configuration
  sg_cidr_blocks         = try(each.value.sg_cidr_blocks, [])
  security_group_ids     = try(each.value.security_group_ids, [])
  sg_custom_ingress_rules = try(each.value.sg_custom_ingress_rules, [])
  sg_custom_egress_rules  = try(each.value.sg_custom_egress_rules, [])
  
  # Route 53 configuration
  hostname_create = try(each.value.hostname_create, false)
  hosted_zone     = try(each.value.hosted_zone, "")
  hostnames       = try(each.value.hostnames, [])
  
  # File system configuration (legacy support)
  fs_type       = try(each.value.fs_type, "EFS")
  efs_mount_dir = try(each.value.efs_mount_dir, "/mnt/efs")
  ebs_mount_dir = try(each.value.ebs_mount_dir, "/mnt/ebs")
  ebs_size      = try(each.value.ebs_size, 40)
  ebs_type      = try(each.value.ebs_type, "gp2")
  
  # User data and logging
  userdata    = try(each.value.userdata, "")
  cwlog_files = try(each.value.cwlog_files, [])
  
  # Spot instance configuration
  on_demand_base_capacity = try(each.value.on_demand_base_capacity, 0)
  on_demand_percentage    = try(each.value.on_demand_percentage, 0)
  
  # Custom launch template
  launch_template_id = try(each.value.launch_template_id, "")
  
  # Public IP configuration
  associate_public_ip_address = try(each.value.associate_public_ip_address, null)
  
  # Tags
  tags = try(each.value.tags, {})
}
