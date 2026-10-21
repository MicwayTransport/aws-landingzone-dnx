# DNX Foundation - Deployment Runbook

**Document Version:** 3.1  
**Last Updated:** February 2026  
**Author:** DNX Solutions  
**Status:** Production Ready  

---

## What the DNX Foundation Delivers

The DNX Foundation provides a secure, scalable, and well-architected multi-account AWS environment following AWS best practices. It delivers:

| Capability | What You Get |
|------------|--------------|
| **Multi-Account Structure** | Isolated accounts for security, logging, networking, and workloads |
| **Security Baseline** | CloudTrail, GuardDuty, Security Hub, Config with centralized monitoring |
| **Centralized Logging** | All security logs aggregated in a dedicated log-archive account |
| **Network Architecture** | Hub-and-spoke VPC design with Transit Gateway connectivity |
| **Backup & Recovery** | Cross-account AWS Backup with automated policies |
| **Identity & Access** | Cross-account IAM roles, OIDC for CI/CD, SSO-ready |
| **Compliance Ready** | Essential Eight, ISO 27001, SOC2, PCI DSS alignment |
| **Infrastructure as Code** | Terraform/Terragrunt with version-controlled, repeatable deployments |

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Account Structure](#account-structure)
3. [Stack Reference](#stack-reference)
4. [Prerequisites](#prerequisites)
5. [Deployment Guide](#deployment-guide)
6. [Operations](#operations)
7. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Repository Structure

```
dnx-foundation/
├── _cf-templates/        # CloudFormation bootstrap templates
│   └── _optional/        # Optional templates (billing, enhanced alarms)
├── _docs/                # Documentation (MkDocs)
├── _scp-policies/        # Service Control Policies
├── _workspaces/          # Terragrunt workspace definitions
│   ├── globals.hcl       # Organization-wide settings
│   ├── accounts.hcl      # Account registry
│   ├── environments.hcl  # Environment configurations
│   ├── remote-state.hcl  # Terraform state management
│   ├── audit/            # Audit account workspaces
│   ├── backup/           # Backup account workspaces
│   ├── dev/              # Dev account workspaces
│   ├── log-archive/      # Log Archive account workspaces
│   ├── prod/             # Prod account workspaces
│   ├── secure-prod/      # Secure Prod account workspaces
│   ├── shared-services/  # Shared Services account workspaces
│   └── stage/            # Stage account workspaces
├── account-template/     # Template for new accounts
├── backup/               # Backup stack (AWS Backup)
├── dns-delegation/       # DNS delegation stack
├── identity/             # Identity stack (IAM, OIDC)
├── network/              # Network stack (VPC, Transit Gateway)
├── platform/             # Platform stack (ECS, EKS, ECR)
├── platform-data/        # Data stack (RDS, ElastiCache, DMS)
└── security/             # Security stack (CloudTrail, GuardDuty, SecurityHub)
```

### Account Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                     Management Account                          │
│                   (Organization, Billing)                       │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│    Audit      │    │  Log Archive  │    │    Backup     │
│  (Security    │    │ (Centralized  │    │ (Cross-acct   │
│   Master)     │    │   Logging)    │    │   Backups)    │
└───────────────┘    └───────────────┘    └───────────────┘
        │
        ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ Network Hub   │───▶│Shared Services│───▶│   Workloads   │
│(Transit GW,   │    │  (CI/CD,      │    │ (Dev, Stage,  │
│  VPN, DNS)    │    │   Tooling)    │    │    Prod)      │
└───────────────┘    └───────────────┘    └───────────────┘
```

---

## Account Structure

| Account | Purpose | Stacks Deployed |
|---------|---------|-----------------|
| **Management** | Organization management, billing | Identity |
| **Audit** | Security monitoring, compliance (master) | Identity → Security |
| **Log Archive** | Centralized logging storage | Identity → Logs |
| **Backup** | Cross-account backups | Identity → Backup |
| **Network Hub** | Transit Gateway, VPN, DNS | Identity → Network |
| **Shared Services** | CI/CD, monitoring, shared tools | Identity → Security → Network |
| **Dev/Stage/Prod** | Workload environments | Identity → Security → Network → Platform |

---

## Stack Reference

### Identity Stack
Cross-account IAM roles, OIDC providers, password policies.

**Deploys to:** All accounts  
**Key resources:** InfraDeployAccess role, OIDC providers, job function roles

### Logs Stack
Centralized S3 buckets for organization-wide security logging.

**Deploys to:** Log Archive account only  
**Key resources:** CloudTrail bucket, GuardDuty bucket, Config bucket  
**⚠️ Must deploy before Security stack**

### Security Stack
CloudTrail, GuardDuty, Security Hub, Config with master/member architecture.

**Deploys to:** All accounts (master in Audit, members elsewhere)  
**Key resources:** CloudTrail with KMS, GuardDuty, Security Hub, Config rules

### Network Stack
Hub-and-spoke VPC architecture with Transit Gateway.

**Deploys to:** Network Hub (hub config), Workload accounts (spoke config)  
**Key resources:** VPCs, Transit Gateway, VPN, Route53, NAT Gateways

### Backup Stack
Cross-account backup and disaster recovery.

**Deploys to:** Backup account  
**Key resources:** Backup vaults, backup policies, lifecycle rules

### Platform Stack
Application hosting infrastructure.

**Deploys to:** Workload accounts  
**Key resources:** ECS clusters, EKS clusters, ECR, ALBs, CloudFront, WAF, EFS, KMS

### Platform Data Stack
Stateful services and databases.

**Deploys to:** Workload accounts  
**Key resources:** RDS, ElastiCache, S3 buckets, DMS, Amazon MQ

---

## Prerequisites

### AWS Setup
- [ ] AWS Organization created
- [ ] All accounts created with proper email pattern: `aws+{account-type}@{domain}`
- [ ] Root MFA enabled on all accounts
- [ ] Account IDs documented

### Tools Required
- Terraform >= 1.5.0
- Terragrunt >= 0.50.0
- AWS CLI >= 2.13.0

### Configuration
- [ ] Update `accounts.hcl` with actual account IDs
- [ ] Update `globals.hcl` with organization name and domain
- [ ] Update `environments.hcl` with environment settings
- [ ] Define IP address ranges for each account

---

## Deployment Guide

### Deployment Order

```
Phase 1: Bootstrap (CloudFormation)
    └── identity-baseline.cf.yml → ALL accounts
    └── security-baseline.cf.yml → Audit account

Phase 2: Identity
    └── identity/ → ALL accounts

Phase 3: Logging ⚠️ CRITICAL
    └── logs/ → Log Archive account ONLY

Phase 4: Security
    └── security/ → Audit (master) → Other accounts (members)

Phase 5: Network
    └── network/ → Network Hub → Workload accounts

Phase 6: Backup
    └── backup/ → Backup account
```

### Phase 1: CloudFormation Bootstrap

Deploy in each account via AWS Console:

```bash
# ALL accounts: identity-baseline
Stack: identity-baseline
Template: _cf-templates/identity-baseline.cf.yml

# Audit account only: security-baseline
Stack: security-baseline
Template: _cf-templates/security-baseline.cf.yml
```

### Phase 2: Identity Stack

```bash
# Deploy to all accounts
cd _workspaces/{account}/ap-southeast-2/identity/
terragrunt init && terragrunt apply
```

### Phase 3: Logs Stack (Critical)

```bash
# Log Archive account ONLY - must complete before security
cd _workspaces/log-archive/ap-southeast-2/logs/
terragrunt init && terragrunt apply

# Verify outputs exist
terragrunt output
# Required: cloudtrail_s3_bucket_name, guardduty_s3_bucket_name, config_s3_bucket_name
```

### Phase 4: Security Stack

```bash
# Audit account first (master)
cd _workspaces/audit/ap-southeast-2/security/
terragrunt init && terragrunt apply

# Then all other accounts (members)
cd _workspaces/{account}/ap-southeast-2/security/
terragrunt init && terragrunt apply
```

### Phase 5: Network Stack

```bash
# Network Hub first
cd _workspaces/network-hub/ap-southeast-2/network/
terragrunt init && terragrunt apply

# Then workload accounts
cd _workspaces/{account}/ap-southeast-2/network/
terragrunt init && terragrunt apply
```

### Phase 6: Backup Stack

```bash
cd _workspaces/backup/ap-southeast-2/backup/
terragrunt init && terragrunt apply
```

---

## Verification

### Post-Deployment Verification

```bash
# Security findings (from Audit account)
aws securityhub get-findings --region ap-southeast-2
aws guardduty list-findings --detector-id <id>

# Verify centralized logging
aws s3 ls s3://{org}-log-archive-cloudtrail-{region}/ --recursive | tail -5

# Check Transit Gateway attachments
aws ec2 describe-transit-gateway-attachments --region ap-southeast-2

# Verify backup jobs
aws backup list-backup-jobs --region ap-southeast-2
```

---

## Troubleshooting

### Cross-Account Role Failures

```bash
# Verify role exists
aws iam get-role --role-name InfraDeployAccess

# Check current identity
aws sts get-caller-identity
```

### Security Stack Fails with "Bucket Not Found"

Logs stack must be deployed first in log-archive account:

```bash
cd _workspaces/log-archive/ap-southeast-2/logs/
terragrunt output
# Verify bucket outputs exist before deploying security
```

### Network Connectivity Issues

```bash
# Check Transit Gateway attachments
aws ec2 describe-transit-gateway-attachments --region ap-southeast-2

# Check route tables
aws ec2 describe-route-tables --region ap-southeast-2
```

---

## Stack Dependencies

| Stack | Depends On | Required By |
|-------|------------|-------------|
| Identity | CloudFormation Bootstrap | All stacks |
| Logs | Identity | Security |
| Security (Master) | Identity, Logs | Security Members, Network |
| Security (Members) | Security Master | Network Spokes |
| Network (Hub) | Security | Network Spokes |
| Network (Spokes) | Network Hub | Platform |
| Backup | Security | - |

---

## Validation Checklist

### Pre-Deployment
- [ ] Account IDs updated in accounts.hcl
- [ ] Organization settings in globals.hcl
- [ ] AWS CLI profiles configured
- [ ] Terraform/Terragrunt versions verified

### Post-Deployment
- [ ] All stacks deployed in correct order
- [ ] Cross-account role assumption working
- [ ] Security Hub aggregation functional
- [ ] GuardDuty findings flowing to master
- [ ] CloudTrail logs in centralized bucket
- [ ] Network connectivity between accounts
- [ ] Backup policies active

---

## Appendix: DNXLabs Module Reference

| Module | Version | Purpose | Stack |
|--------|---------|---------|-------|
| terraform-aws-vcs-oidc | 0.1.0 | GitHub/GitLab/Bitbucket OIDC | Identity |
| terraform-aws-sns | 0.2.5 | SNS notifications | Security, Backup |
| terraform-aws-chatbot | 3.0.0 | Slack/Teams notifications | Security |
| terraform-aws-cloudtrail-notification | 4.0.0 | CloudTrail alerting | Security |
| terraform-aws-guardduty-alerts | 1.0.0 | GuardDuty findings alerts | Security |
| terraform-aws-securityhub | 1.1.0 | Security Hub master/member | Security |
| terraform-aws-network | 2.4.0 | VPC, subnets, routing, NAT | Network |
| terraform-aws-transit-gateway | 1.13.0 | Transit Gateway hub/spoke | Network |
| terraform-aws-client-vpn | 0.11.0 | AWS Client VPN | Network |
| terraform-aws-vpn-connection | 0.3.0 | Site-to-site VPN | Network |
| terraform-aws-acm-certificate | 0.3.1 | SSL/TLS certificates | Network |
| terraform-aws-backup | 3.0.4 | AWS Backup vaults and policies | Backup |
| terraform-aws-ecs | 6.21.0 | ECS clusters | Platform |
| terraform-aws-ecs-app | 7.5.0 | ECS services with ALB | Platform |
| terraform-aws-ecs-app-worker | 2.7.0 | ECS worker services | Platform |
| terraform-aws-ecr | 2.3.3 | ECR repositories | Platform |
| terraform-aws-static-app | 2.5.1 | CloudFront + S3 static apps | Platform |
| terraform-aws-stateful | 4.2.0 | EC2 stateful instances | Platform, Platform Data |
| terraform-aws-log-exporter | 1.4.0 | CloudWatch to S3 export | Platform |
| terraform-aws-rds | 0.16.5 | RDS databases | Platform Data |
| terraform-aws-rds-scheduler | 1.2.3 | RDS start/stop scheduling | Platform Data |
| terraform-aws-elasticache | 1.1.1 | ElastiCache Redis | Platform Data |

**Optional/Commented modules available:**
| Module | Version | Purpose | Stack |
|--------|---------|---------|-------|
| terraform-aws-openvpn | 2.0.0 | OpenVPN server | Network |
| terraform-aws-ecs-app-front | 1.15.0 | ECS with CloudFront | Platform |
| terraform-aws-ecs-app-nlb | 1.12.0 | ECS with NLB | Platform |
| terraform-aws-db-monitoring | 1.4.0 | RDS monitoring | Platform Data |
| terraform-aws-dms-endpoint | 0.0.3 | DMS endpoints | Platform Data |
| terraform-aws-dms-replication-task | 0.0.4 | DMS tasks | Platform Data |
| terraform-aws-dms-replication-instance | 0.0.2 | DMS instances | Platform Data |

All modules are open source at [github.com/DNXLabs](https://github.com/DNXLabs).

---

*The DNX Foundation implements AWS Well-Architected multi-account best practices with infrastructure as code for repeatable, auditable deployments.*

*Built and maintained by [DNX Solutions](https://dnx.solutions) - Most modules are open source at [github.com/DNXLabs](https://github.com/DNXLabs)*
