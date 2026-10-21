# DNS Delegation Automation Guide

## Overview

The `dns-delegation` stack automates Route53 NS record creation for subdomain delegation from a parent zone to child zones across multiple AWS accounts.

**Problem Solved**: Manually copying nameservers from child zones to parent zone is error-prone and doesn't scale.

**Solution**: Terraform automatically creates NS records in the parent zone using Terragrunt dependencies to reference child zone nameservers.

---

## Architecture

```
Parent Zone (shared-services account)
  infra.example.com
    ├── NS dev → [ns-1.awsdns.com, ns-2.awsdns.com, ...]
    ├── NS prod → [ns-3.awsdns.com, ns-4.awsdns.com, ...]
    └── NS qa → [ns-5.awsdns.com, ns-6.awsdns.com, ...]

Child Zones (workload accounts)
  dev.infra.example.com (dev account)
  prod.infra.example.com (prod account)
  qa.infra.example.com (qa account)
```

**Benefits:**
- ✅ Automated NS record creation
- ✅ No manual nameserver copy-paste
- ✅ Enables automatic ACM certificate validation
- ✅ Version controlled DNS delegation
- ✅ Scales to unlimited environments

---

## Prerequisites

1. **Parent zone exists** in shared-services account (created by network stack)
2. **Child zones exist** in workload accounts (created by network stacks)
3. **Network stacks output nameservers** via `route53_name_servers` output

---

## Directory Structure

```
_workspaces/
  └── shared-services/
      └── {region}/
          ├── network/           # Creates parent zone
          └── dns-delegation/    # Creates NS records (this stack)
              └── terragrunt.hcl
```

**Why separate stack?**
- Isolates DNS changes from network infrastructure
- Can destroy/recreate network without affecting DNS
- Clear ownership boundary for DNS team
- Easier to apply different lifecycle rules

---

## Configuration

### Step 1: Create DNS Delegation Stack

Create `_workspaces/shared-services/{region}/dns-delegation/terragrunt.hcl`:

```hcl
terraform {
  source = "${get_repo_root()}/dns-delegation"
}

include "remote_state" {
  path = find_in_parent_folders("remote-state.hcl")
}

include "globals" {
  path = find_in_parent_folders("globals.hcl")
}

include "accounts" {
  path = find_in_parent_folders("accounts.hcl")
}

locals {
  globals  = read_terragrunt_config(find_in_parent_folders("globals.hcl")).locals
  accounts = read_terragrunt_config(find_in_parent_folders("accounts.hcl")).locals
  
  current_account = local.accounts.accounts.shared-services
}

iam_role = local.accounts.iam_roles.shared-services

# Dependency on parent zone
dependency "parent_network" {
  config_path = "${get_repo_root()}/_workspaces/shared-services/{region}/network"
}

# Dependencies on child zones
dependency "dev_network" {
  config_path = "${get_repo_root()}/_workspaces/dev/{region}/network"
  
  mock_outputs = {
    route53_name_servers = {
      "dev.infra.example.com" = ["ns-mock.awsdns.com"]
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  aws_region     = local.globals.default_aws_region
  aws_account_id = local.current_account.account_id
  
  parent_zone_id   = dependency.parent_network.outputs.route53_hosted_zone_ids["infra.example.com"]
  parent_zone_name = "infra.example.com"
  
  child_zones = {
    dev = {
      subdomain    = "dev"
      name_servers = dependency.dev_network.outputs.route53_name_servers["dev.infra.example.com"]
    }
  }
}
```

### Step 2: Ensure Network Stacks Output Nameservers

The network module already outputs nameservers. Verify with:

```bash
cd _workspaces/dev/{region}/network
terragrunt output route53_name_servers
```

Expected output:
```json
{
  "dev.infra.example.com": [
    "ns-1234.awsdns-12.org",
    "ns-5678.awsdns-34.co.uk",
    "ns-9012.awsdns-56.com",
    "ns-3456.awsdns-78.net"
  ]
}
```

---

## Deployment

### Deployment Order

**Critical**: Deploy in this order to avoid dependency errors:

1. **Deploy parent zone** (shared-services network)
   ```bash
   cd _workspaces/shared-services/{region}/network
   terragrunt apply
   ```

2. **Deploy child zones** (workload account networks)
   ```bash
   cd _workspaces/dev/{region}/network
   terragrunt apply
   
   cd _workspaces/prod/{region}/network
   terragrunt apply
   ```

3. **Deploy DNS delegation** (creates NS records)
   ```bash
   cd _workspaces/shared-services/{region}/dns-delegation
   terragrunt apply
   ```

### Expected Terraform Plan

```
Terraform will perform the following actions:

  # aws_route53_record.child_zone_ns["dev"] will be created
  + resource "aws_route53_record" "child_zone_ns" {
      + name    = "dev"
      + records = [
          + "ns-1234.awsdns-12.org",
          + "ns-5678.awsdns-34.co.uk",
          + "ns-9012.awsdns-56.com",
          + "ns-3456.awsdns-78.net",
        ]
      + ttl     = 172800
      + type    = "NS"
      + zone_id = "Z0123456789ABC"
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

---

## Validation

### 1. Verify NS Records Created

```bash
dig NS dev.infra.example.com @8.8.8.8
```

**Expected output:**
```
dev.infra.example.com. 172800 IN NS ns-1234.awsdns-12.org.
dev.infra.example.com. 172800 IN NS ns-5678.awsdns-34.co.uk.
dev.infra.example.com. 172800 IN NS ns-9012.awsdns-56.com.
dev.infra.example.com. 172800 IN NS ns-3456.awsdns-78.net.
```

### 2. Verify DNS Resolution Works

```bash
dig test.dev.infra.example.com @8.8.8.8
```

Should resolve (even if NXDOMAIN, delegation is working).

### 3. Verify ACM Certificate Validation

If you have ACM certificates in child zones:

```bash
aws acm list-certificates --region {region}
```

**Status should change from `PENDING_VALIDATION` to `ISSUED`** within 5-30 minutes after NS delegation.

### 4. Check Validation Records

```bash
# Get validation CNAME from ACM
aws acm describe-certificate --certificate-arn {arn} --region {region}

# Verify it's resolvable
dig _validation-string.dev.infra.example.com CNAME
```

---

## Adding More Environments

To add additional environments (qa, stage, etc.):

1. **Add dependency** in `dns-delegation/terragrunt.hcl`:
   ```hcl
   dependency "qa_network" {
     config_path = "${get_repo_root()}/_workspaces/qa/{region}/network"
     mock_outputs = { ... }
   }
   ```

2. **Add to child_zones**:
   ```hcl
   child_zones = {
     dev = { ... }
     qa = {
       subdomain    = "qa"
       name_servers = dependency.qa_network.outputs.route53_name_servers["qa.infra.example.com"]
     }
   }
   ```

3. **Deploy**:
   ```bash
   cd _workspaces/shared-services/{region}/dns-delegation
   terragrunt apply
   ```

---

## Troubleshooting

### NS Records Not Resolving

**Symptom**: `dig NS dev.infra.example.com` returns nothing

**Causes**:
1. DNS propagation delay (wait 5-10 minutes)
2. NS records not created in parent zone
3. Wrong parent zone ID

**Fix**:
```bash
# Verify NS records exist in Route53
aws route53 list-resource-record-sets \
  --hosted-zone-id {parent_zone_id} \
  --query "ResourceRecordSets[?Type=='NS']"
```

### ACM Certificate Stuck in PENDING_VALIDATION

**Symptom**: Certificate doesn't validate after 30+ minutes

**Causes**:
1. NS delegation not working
2. Validation CNAME not created in child zone
3. Wrong hosted zone for certificate

**Fix**:
```bash
# 1. Verify NS delegation works
dig NS dev.infra.example.com

# 2. Check validation record exists
aws acm describe-certificate --certificate-arn {arn}
dig {validation-cname} CNAME

# 3. Verify certificate is in correct zone
aws acm list-certificates --region {region}
```

### Terraform Dependency Errors

**Symptom**: `Error: dependency.dev_network.outputs is null`

**Cause**: Child zone not deployed yet

**Fix**: Deploy child zones before dns-delegation stack (see Deployment Order)

---

## Lifecycle Management

### Preventing Accidental Deletion

If your team prefers manual DNS control, add lifecycle rules:

```hcl
resource "aws_route53_record" "child_zone_ns" {
  # ... configuration ...
  
  lifecycle {
    prevent_destroy = true      # Blocks terraform destroy
    ignore_changes  = [records] # Allows manual updates in console
  }
}
```

**Trade-offs**:
- ✅ Safe from accidental deletion
- ✅ Can update manually in console
- ❌ Terraform won't detect drift
- ❌ Won't auto-update if child nameservers change

### Deleting NS Records

To delete NS records:

1. **Without lifecycle protection**: `terragrunt destroy`
2. **With lifecycle protection**: Delete manually in AWS Console, then remove from Terraform state

---

## Best Practices

1. **Deploy child zones first**: Always deploy workload network stacks before dns-delegation
2. **Use mock outputs**: Allows planning before child zones exist
3. **Separate stack**: Keep DNS delegation isolated from network infrastructure
4. **Monitor ACM validation**: Set up alerts for stuck certificate validations
5. **Document nameserver changes**: If child nameservers change, update dns-delegation stack

---

## Integration with ACM

This stack enables automatic ACM certificate validation:

1. **Network stack** creates child zone and ACM certificate
2. **ACM** creates validation CNAME records in child zone
3. **DNS delegation stack** creates NS records in parent zone
4. **DNS resolution** works: validation records become resolvable
5. **ACM** detects validation records and issues certificate

**Timeline**: Certificate typically validates within 5-30 minutes after NS delegation.

---

## Example: Multi-Environment Setup

```hcl
child_zones = {
  dev = {
    subdomain    = "dev"
    name_servers = dependency.dev_network.outputs.route53_name_servers["dev.infra.example.com"]
  }
  qa = {
    subdomain    = "qa"
    name_servers = dependency.qa_network.outputs.route53_name_servers["qa.infra.example.com"]
  }
  stage = {
    subdomain    = "stage"
    name_servers = dependency.stage_network.outputs.route53_name_servers["stage.infra.example.com"]
  }
  prod = {
    subdomain    = "prod"
    name_servers = dependency.prod_network.outputs.route53_name_servers["prod.infra.example.com"]
  }
}
```

**Result**: 4 NS records created in parent zone, all child zones delegated automatically.

---

## References

- [AWS Route53 Subdomain Delegation](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingNewSubdomain.html)
- [Terraform aws_route53_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)
- [Terragrunt Dependencies](https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#dependency)
- [ACM DNS Validation](https://docs.aws.amazon.com/acm/latest/userguide/dns-validation.html)

---

**Last Updated**: 2026-01-21  
**Tested With**: Terraform 1.5+, Terragrunt 0.50+, AWS Provider 6.28+
