# =============================================================================
# SHARED SERVICES ACCOUNT - NETWORK STACK
# =============================================================================
# This file configures network infrastructure for the shared services account.
# The shared services account hosts shared networking resources and connectivity.
# 
# STACK PURPOSE: Shared networking infrastructure and connectivity
# ACCOUNT: shared-services (shared resources and tools across organization)
# REGION: ap-southeast-2
# =============================================================================

terraform {
  source = "${get_repo_root()}/network"
}

include "remote_state" {
  path = find_in_parent_folders("remote-state.hcl")
}

# Include centralized configurations
include "globals" {
  path = find_in_parent_folders("globals.hcl")
}

include "accounts" {
  path = find_in_parent_folders("accounts.hcl")
}

include "environments"{
  path = find_in_parent_folders("environments.hcl")
}

# Load centralized configurations
locals {
  globals  = read_terragrunt_config(find_in_parent_folders("globals.hcl")).locals
  accounts = read_terragrunt_config(find_in_parent_folders("accounts.hcl")).locals
  environments = read_terragrunt_config(find_in_parent_folders("environments.hcl")).locals

  # This is the shared-services account
  current_account = local.accounts.accounts.shared-services
  
  # Calculate private subnet CIDRs, this need to be aligned with the AZ, subnet offset and size configurations.
  private_subnet_cidrs = [
    cidrsubnet(local.environments.vpc_cidrs.shared-services, 4, 4),  # 10.10.64.0/20 (AZ1)
    cidrsubnet(local.environments.vpc_cidrs.shared-services, 4, 5)   # 10.10.80.0/20 (AZ2)
  ]
}

# Use centralized IAM role
iam_role = local.accounts.iam_roles.shared-services

inputs = {
  aws_region     = local.globals.default_aws_region
  aws_account_id = local.current_account.account_id
  account_name   = local.current_account.name
  org_name       = local.globals.org_name

  network = {
    enabled                        = true #
    name                           = local.current_account.name
    vpc_cidr                       = local.environments.vpc_cidrs.shared-services
    vpc_newbits                    = 4              # size of subnets:  16 + 4 = /20
    max_az                         = 2
    nat                            = true
    multi_nat                      = false
    public_nacl_inbound_tcp_ports  = [80, 443]
    public_nacl_outbound_tcp_ports = [0]
    
    public_netnum_offset           = 0     # start from .0
    private_netnum_offset          = 4     # start from .64
    secure_netnum_offset           = 8     # start from .128
    vpc_cidr_summ                  = "/18" #sumarize route per tier
    vpc_endpoints                  = [
      # Required for EKS private clusters and other services if not using NAT 
      # {
      #   name = "eks"
      #   policy = null
      #   allowed_cidrs = local.private_subnet_cidrs
      # },
      # {
      #   name = "ec2"
      #   policy = null
      #   allowed_cidrs = local.private_subnet_cidrs
      # },
      # {
      #   name = "sts"
      #   policy = null
      #   allowed_cidrs = local.private_subnet_cidrs
      # },
      # {
      #   name = "logs"
      #   policy = null
      #   allowed_cidrs = local.private_subnet_cidrs
      # },
      # {
      #   name = "ecr.dkr"
      #   policy = null
      #   allowed_cidrs = local.private_subnet_cidrs
      # },
      # {
      #   name = "ecr.api"
      #   policy = null
      #   allowed_cidrs = local.private_subnet_cidrs
      # }

    ]
    vpc_endpoint_dynamodb_gateway  = false
    vpc_endpoint_s3_gateway        = true
    peering                        = []
  }

  vpn = {
    enabled = false
    name    = local.current_account.name
  }

  # 

  domain = {
    enabled = false
    zones = [
      {
        route53_domain = local.environments.domain_patterns.shared-services
        private        = false
      }
    ]
  }

  acm = {
    certificates = [
      # {
      #   name = "default"
      #   domain_names = [
      #     local.environments.domain_patterns.shared-services,
      #     "*.${local.environments.domain_patterns.shared-services}"
      #   ]
      #   hosted_zone = local.environments.domain_patterns.shared-services
      # }
    ]
  }

  route53_resolver = {
    outbound_rules = {
      domains = []
    }
  }

  transit_gateway = {
    enabled = false
    attachment = {
      enabled                    = true
      transit_gateway_account_id = local.accounts.accounts.network-hub.account_id
      public_route               = []
      private_route              = [
        {
          # VPN access to dev environment
          cidr = local.environments.vpc_cidrs.vpn-cidr  # 10.0.64.0/18
          protocol = "tcp"
          nacl_inbound_ports: []
          nacl_outbound_ports: []
        },
        {
          # Dev environment access - All ports (private environment)
          cidr = local.environments.vpc_cidrs.dev  # 10.10.0.0/16
          protocol = "tcp"
          nacl_inbound_ports: [0]  # All ports (0 = all ports 1-65535)
          nacl_outbound_ports: []
        },
        {
          # Dev environment access - All ports (private environment)
          cidr = local.environments.vpc_cidrs.dev  # 10.10.0.0/16
          protocol = "udp"
          nacl_inbound_ports: [0]  # All ports (0 = all ports 1-65535)
          nacl_outbound_ports: []
        },
        {
          # Prod environment access - Essential AD ports (TCP)
          cidr = local.environments.vpc_cidrs.prod # 10.30.0.0/16
          protocol = "tcp"
          nacl_inbound_ports: [0]  # DNS, RPC, NetBIOS, LDAP, SMB, Kerberos
          nacl_outbound_ports: []
        },
        {
          # Prod environment access - Essential AD ports (UDP)
          cidr = local.environments.vpc_cidrs.prod  # 10.30.0.0/16
          protocol = "udp"
          nacl_inbound_ports: [0]  # DNS, LDAP, Kerberos
          nacl_outbound_ports: []
        }
        ]
      secure_route               = []
    }
  }

}
