# This file configures the network infrastructure for the PLACEHOLDER environment.
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

  # This is the PLACEHOLDER account
  current_account = local.accounts.accounts.PLACEHOLDER
}

# Use centralized IAM role
iam_role = local.accounts.iam_roles.PLACEHOLDER

inputs = {
  aws_region     = local.globals.default_aws_region
  aws_account_id = local.current_account.account_id
  account_name   = local.current_account.name
  org_name       = local.globals.org_name

  network = {
    enabled                        = true #
    name                           = local.current_account.name
    vpc_cidr                       = local.environments.vpc_cidrs.PLACEHOLDER
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
    vpc_endpoints                  = []
    vpc_endpoint_dynamodb_gateway  = false
    vpc_endpoint_s3_gateway        = true
    peering                        = []
  }

  vpn = {
    enabled = false
    name    = local.current_account.name
  }

  openvpn = {
    name           = "devs-openvpn"
    enabled        = false
    hosted_zone    = ""
    route_push     = "10.135.0.0 255.255.0.0"
    instance_types = ["t4g.nano", "t3a.nano", "t3.nano"]
    domain_name    = ""
    security_group = {
      inbound = [
        { cidr_blocks = ["10.135.0.0/16"] }
      ],
      outbound = [
        { cidr_blocks = ["0.0.0.0/0"] }
      ]
    }
  }

  domain = {
    enabled = true
    zones = [
      {
        route53_domain = local.environments.domain_patterns.PLACEHOLDER
        private        = false
      }
    ]
  }

  acm = {
    certificates = [
      {
        name = "default"
        domain_names = [
          local.environments.domain_patterns.PLACEHOLDER,
          "*.${local.environments.domain_patterns.PLACEHOLDER}"
        ]
        hosted_zone = local.environments.domain_patterns.PLACEHOLDER
      }
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
      enabled                    = false
      transit_gateway_account_id = ""
      public_route               = []
      private_route              = [
        # Example routing rules for Transit Gateway connectivity
        # Uncomment and modify as needed when Transit Gateway is enabled
        # {
        #   # VPN access to staging environment
        #   cidr = local.environments.vpc_cidrs.strongcare_stage  # 10.31.0.0/16
        #   protocol = "tcp"
        #   nacl_inbound_ports: []
        #   nacl_outbound_ports: []
        # },
        # {
        #   # Shared Services Production access - All ports
        #   cidr = local.environments.vpc_cidrs.shared_services_prod  # 10.20.0.0/16
        #   protocol = "tcp"
        #   nacl_inbound_ports: [0]  # All ports (0 = all ports 1-65535)
        #   nacl_outbound_ports: []
        # },
        # {
        #   # Shared Services Production access - UDP
        #   cidr = local.environments.vpc_cidrs.shared_services_prod  # 10.20.0.0/16
        #   protocol = "udp"
        #   nacl_inbound_ports: [0]  # All ports (0 = all ports 1-65535)
        #   nacl_outbound_ports: []
        # },
        # {
        #   # Network Hub Production access - Essential ports (TCP)
        #   cidr = local.environments.vpc_cidrs.network_hub_prod # 10.10.0.0/16
        #   protocol = "tcp"
        #   nacl_inbound_ports: [0]  # DNS, RPC, NetBIOS, LDAP, SMB, Kerberos
        #   nacl_outbound_ports: []
        # },
        # {
        #   # Network Hub Production access - Essential ports (UDP)
        #   cidr = local.environments.vpc_cidrs.network_hub_prod  # 10.10.0.0/16
        #   protocol = "udp"
        #   nacl_inbound_ports: [0]  # DNS, LDAP, Kerberos
        #   nacl_outbound_ports: []
        # }
        ]
      secure_route               = []
    }
  }

}