# This file is configure the network infrastructure for the prod environment.
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

  # This is the prod account
  current_account = local.accounts.accounts.prod
}

# Use centralized IAM role
iam_role = local.accounts.iam_roles.prod

inputs = {
  aws_region     = local.globals.default_aws_region
  aws_account_id = local.current_account.account_id
  account_name   = local.current_account.name
  org_name       = local.globals.org_name

  network = {
    enabled                        = true #
    name                           = local.current_account.name
    vpc_cidr                       = local.environments.vpc_cidrs.prod
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
        route53_domain = local.environments.domain_patterns.prod
        private        = false
      }
    ]
  }

  acm = {
    certificates = [
      {
        name = "default"
        domain_names = [
          local.environments.domain_patterns.prod,
          "*.${local.environments.domain_patterns.prod}"
        ]
        hosted_zone = local.environments.domain_patterns.prod
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
      private_route              = []
      secure_route               = []
    }
  }

}
