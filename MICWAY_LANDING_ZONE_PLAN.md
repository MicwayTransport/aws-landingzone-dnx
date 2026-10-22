# Micway AWS Landing Zone — what DNX gave us, how it works, and how we use it

**Written:** 2026-10-23
**Source reviewed:** `aws-landingzone-dnx/` (337 files, one commit: `e68784b Initial commit`). I read the runbook, README, every doc under `_docs/`, all CloudFormation templates, all four SCP files, every `_workspaces/` config, and the Terraform in `security`, `identity`, `network`, `backup`, `dns-delegation`, plus the GitHub workflows. I skimmed `platform`, `platform-data` and the vendored `waf` / `eks` modules, because we are unlikely to use them (see §6).
**Nothing was deployed or changed.** This is a reading and a plan.

---

## 1. The short version

DNX gave us a **kit for building a multi-account AWS setup** (a "landing zone"). It is not a product you click "install" on. It is:

1. A few **CloudFormation** files you paste into each new AWS account by hand, once, to create the "doors" Terraform will walk through.
2. A set of **Terraform stacks** (identity, security, network, backup, platform, platform-data) that build the real things.
3. **Terragrunt** config (`_workspaces/`) that says *which stack goes into which account with which settings*.
4. Four **SCP** files (organisation-wide "you may never do this" rules).
5. **GitHub Actions** workflows to run it all from CI.
6. A **MkDocs** site generator that turns the deployed outputs into documentation.

The repo is a **template**. Every account ID is `PLACEHOLDER-…`, the organisation name is the literal string `organization-name`, and there are leftovers from other DNX customers in it (§9). It will not run until we fill it in and clean it.

**My recommendation, in one paragraph.** Use this kit for what it is good at: the account structure, the security and logging baseline, the guardrails (SCPs), identity, and backups. Do **not** deploy its network / ECS / EKS / RDS stacks, because Micway's platform is serverless (IoT Core, Lambda, DynamoDB, Step Functions) and built with CDK. Create **6 new accounts** (§5), keep the two existing accounts, `478043880000` (the IoT platform, which becomes **prod**) and a bigger **legacy** account, **outside the Organization** until the baseline works, then import both (Phase 8), later moving workloads from legacy into prod, and **turn off DNX's built-in admin access** to our accounts unless a contract needs it (§9, item 1). Attach the SCPs **last**, not first (§9, item 5).

---

## 2. How it works, in plain language

### 2.1 The three tools, and an analogy

| Tool | What it is | Analogy |
|---|---|---|
| **Terraform** | Reads `.tf` files and creates AWS resources to match them. Remembers what it built in a "state file". | A builder working from blueprints, with a notebook of what is already built. |
| **Terragrunt** | A wrapper around Terraform. Lets us reuse one set of blueprints for many accounts, each with its own settings file. | The site manager: "use blueprint *security*, but for the *dev* plot, with these options." |
| **CloudFormation** | AWS's own version of Terraform. DNX uses it only for the very first step (bootstrapping), because Terraform needs some things to exist before it can start. | The person who builds the front gate so the builder can get onto the site. |

### 2.2 The two layers of folders

```
aws-landingzone-dnx/
│
├── security/  identity/  network/  backup/  platform/ ...     ← THE BLUEPRINTS (Terraform code)
│        "what can be built"; written once, shared by all accounts
│
└── _workspaces/                                               ← THE SETTINGS (Terragrunt)
        ├── globals.hcl        org name, region, tags         (same for everyone)
        ├── accounts.hcl       list of accounts + their IDs   (single source of truth)
        ├── environments.hcl   network ranges + domain names
        ├── remote-state.hcl   where Terraform keeps its notebook
        ├── dev/ap-southeast-2/security/terragrunt.hcl   ← "run blueprint security in account dev"
        ├── prod/ap-southeast-2/security/terragrunt.hcl
        └── ...
```

So **a "workspace" is just a folder containing one `terragrunt.hcl`**. The path tells you the account, region and stack. You `cd` into it and run `terragrunt plan` / `terragrunt apply`.

### 2.3 What one workspace file looks like (real excerpt, shortened)

`_workspaces/dev/ap-southeast-2/security/terragrunt.hcl`:

```hcl
terraform { source = "${get_repo_root()}/security" }      # which blueprint

include "remote_state" { path = find_in_parent_folders("remote-state.hcl") }   # shared settings
include "globals"      { path = find_in_parent_folders("globals.hcl") }
include "accounts"     { path = find_in_parent_folders("accounts.hcl") }

locals { current_account = local.accounts.accounts.dev }     # which account this is
iam_role = local.accounts.iam_roles.dev                      # the role Terraform will "become"

dependency "logs"  { config_path = ".../log-archive/ap-southeast-2/logs" }   # must be built first
dependency "audit" { config_path = ".../audit/ap-southeast-2/security" }     # must be built first

inputs = {
  cloudtrail = { enabled = true, role = "member", s3_bucket_name = dependency.logs.outputs.cloudtrail_s3_bucket_name, ... }
  guardduty  = { enabled = true, role = "member", admin_account_id = <audit account id> }
  securityhub = { enabled = true, role = "member", ... }
  config     = { enabled = true, role = "member", ... }
  ebs_encryption_by_default = { enabled = true }
}
```

Read it as: *"In the dev account, run the security blueprint as a **member**: turn on CloudTrail, GuardDuty, Security Hub and Config, send logs to the log-archive buckets, and report to the audit account."*

Every setting is a block with `enabled = true/false`. That is the main on/off switch for everything in this kit.

### 2.4 How Terraform gets into each account (the "role chain")

This is the part people get stuck on, so here it is slowly.

1. A human (or GitHub Actions) has some credentials.
2. Every account has a role called **`InfraDeployAccess`** (created by the CloudFormation `identity-baseline`). It has **full admin** (`Action: *`, `Resource: *`). Terragrunt sets `iam_role = arn:aws:iam::<account>:role/InfraDeployAccess`, so Terraform *becomes* that role in whichever account it is building in.
3. Terraform's notebook (state file) lives in an S3 bucket `micway-terraform-backend` in **one** account. To read and write it, Terraform assumes a second role, **`TerraformBackendAccess`**, in that account (see `remote-state.hcl`).
4. Whoever you are at step 1 must be *allowed to assume* `InfraDeployAccess` in each account. That is controlled by the `TrustArns` parameter in `identity-baseline`.

```
You / CI ──assume──▶ InfraDeployAccess (in dev)  ──▶ builds resources in dev
                └──▶ TerraformBackendAccess (in shared-services) ──▶ reads/writes state bucket
```

### 2.5 Stacks and who they are for

| Stack | Creates (plain English) | Goes into |
|---|---|---|
| **identity** | Standard human roles (Admin, ReadOnly, PowerUser, SecurityAudit, DB admin, …), a strict password policy, an AWS Support role, a `CIDeployAccess` role for pipelines, GitHub/GitLab/Bitbucket **OIDC** login for CI (no stored keys) | every account |
| **security** | CloudTrail (the "who did what" log) with its own encryption key, **GuardDuty** (threat detection), **Security Hub** (a dashboard that collects findings, with CIS and AWS best-practice checks), **AWS Config** (records every resource change), EBS encryption on by default, optional Chatbot/Slack alerts, optional auditor role, optional Detective | every account. One account (**audit**) is the **master**, the rest are **members** |
| **security** *(run again with `log_buckets`)* | The locked-away S3 buckets that hold everyone's logs: `micway-log-archive-cloudtrail-ap-southeast-2`, `-config-`, `-guardduty-`, `-logs-`, `-alb-access-logs-`, `-s3-access-logs-`, `-cloudfront-access-logs-`. Moves old logs to cheaper storage (Glacier) after 90 days | **log-archive** account only (workspace is named `logs`) |
| **network** | A VPC per account (public / private / secure subnets), NAT gateway, network ACLs, Route53 zone, ACM certificates, optional VPN, optional Transit Gateway ("cloud router" joining VPCs) | accounts that run servers/containers |
| **dns-delegation** | Automatically creates the NS records that hand `dev.example.com` to the dev account | the account holding the parent DNS zone |
| **backup** | AWS Backup vaults and schedules (continuous, weekly, monthly), copies backups into a central vault in another account, alerts on failure | workload accounts + a central **backup** account |
| **platform** | ECS (containers), EKS (Kubernetes), ECR, load balancers, CloudFront, WAF, EFS, secrets | workload accounts |
| **platform-data** | RDS, ElastiCache, S3 buckets, Amazon MQ, DMS | workload accounts |

### 2.6 "Master" and "member" (important for security)

GuardDuty and Security Hub work as a **hub and spokes**. The audit account is the hub (`role = "master"`) and it **invites** every other account (`role = "member"`), which then accepts. The audit account sees everyone's findings in one place. The list of who gets invited is `organization.members` in `_workspaces/audit/.../security/terragrunt.hcl`. **Every new account must be added to that list by hand**, and the audit stack re-applied *before* the new account's member stack.

(This invite style is the older approach. AWS now offers "delegated administrator" through AWS Organizations, which auto-enrols new accounts. See §8.)

### 2.7 The SCPs (the guardrails)

A **Service Control Policy** is a rule on the AWS Organization that overrides everything, even an account admin. It can only *remove* permissions, never grant them. DNX supplies:

| File | What it blocks |
|---|---|
| `scp-region.json` | Any action outside `ap-southeast-2`, **except** a list of global services (IAM, Route53, CloudFront, ACM, KMS, support, billing, STS, …) |
| `audit-security-lock.json` | Deleting log-bucket objects; **any** change to GuardDuty; deleting AWS Config recorder/rules; stopping/deleting CloudTrail; leaving the organisation |
| `expensive-services.json` | Buying domains, reserved instances, Savings Plans, Marketplace subscriptions, Shield Advanced, Bedrock provisioned throughput, Glacier/S3/Backup **vault lock** and object lock |
| `scp-policies.yml` | The first two again as a CloudFormation template, plus: no root access keys, and **no root-user use** of ec2/lambda/ecs/cloudfront/rds/s3/iam/apigateway |

Two key facts: **SCPs never apply to the management account**, and they apply to *everyone* including our own deploy role (see §9 item 5).

---

## 3. What we can configure (the knobs)

### 3.1 The four central files in `_workspaces/`

| File | Set this | Example for Micway |
|---|---|---|
| `globals.hcl` | `organization.name`, `org_name`, `default_aws_region`, `global_tags` | `micway`, `ap-southeast-2`. ⚠️ Use **`micway`** (no hyphen): the CloudFormation `OrgName` only allows letters/numbers, and the state bucket name must match on both sides |
| `accounts.hcl` | one entry per account: `account_id`, `name`, `email` | see §5 |
| `environments.hcl` | `vpc_cidrs` (network ranges) and `domain_patterns` (DNS names) per environment | `prod = "prod.micway.cloud"` or similar. We have not been told our domain, so I have not guessed |
| `remote-state.hcl` | bucket name and the role to read it | normally leave alone; it derives from `globals.hcl` and the `shared-services` account |

`global_tags` currently contains DNX's partner tag `"aws-apn-id" = "pc:3dzx7t9es09krh7lxyl30xkj5"`, which gets stamped on **every** resource. Replace it with our own tags (e.g. `Owner`, `CostCentre`) unless the DNX partner arrangement wants it.

### 3.2 Per-stack switches (examples)

```hcl
# Security: turn on only what we want
cloudtrail  = { enabled = true,  role = "member", global = true, log_group_retention_in_days = 365 }
guardduty   = { enabled = true,  role = "member", admin_account_id = "<audit id>" }
securityhub = { enabled = true,  role = "master",
                subscriptions = { cis = true, foundational = true, pci = false } }   # pci not needed
config      = { enabled = true,  role = "member", global = true }   # "global" in ONE region only
detective   = { enabled = false }                                    # extra cost, off by default
chatbot     = { enabled = true, slack_targets = [ { slack_channel_name = "aws-alerts", ... } ] }
notifications = { enabled = true, email = "aws+audit@micway.com.au", allow_from_account_ids = [ ... ] }

# Identity
iam_password_policy = { enabled = true }
aws_support_role    = { enabled = true }
oidc = { enabled = true, vendor = "github", org = "MicwayTransport",
         roles = [ { name = "InfraDeployGitHub", assume_role = "InfraDeployAccess",
                     policy_sets = ["ADMIN"], all_repos = false, repos = ["aws-landingzone-dnx"] } ] }

# Log archive
log_buckets = { enabled = true, transition_to_glacier_in_days = 90,
                allow_from_account_ids = { audit = "...", dev = "...", ... } }   # EVERY account here
```

### 3.3 The CloudFormation bootstrap parameters

| Template | Run in | Key parameters |
|---|---|---|
| `identity-baseline.cf.yml` | **every** account | `OrgName` (letters/numbers, max 14), `TrustArns` (who may assume `InfraDeployAccess`), `DNX` (default **true**), `DNXAutomation` (default **true**), `CreateInfraDeployUser`, `SAMLProviderArn`/`SAMLProviderDocument` |
| `terraform-backend.cf.yml` | **one** account (state home) | `OrgName`, `RoleARNs` (every account's `InfraDeployAccess`), `KMSKeyARN`, `CitadelAutomation` (default **true**) |
| `security-baseline.cf.yml` | audit (optional) | A *simple* CloudTrail + alarms, an alternative to the Terraform security stack. **Do not use both**; they would create duplicate trails |
| `_optional/master-account/billing.cf.yml` | management, **us-east-1** | `BudgetEnabled`, `BudgetAmount` (USD), `BudgetThreshold` %, `BudgetEmail`, `CostAnomaly`, `CostAnomalyThreshold` |
| `_optional/master-account/cloudtrail-alarms*.cf.yml` | management | CIS-style alarms: root use, console login without MFA, IAM policy changes, CloudTrail/Config/S3 policy changes, KMS key deletion, unauthorised API calls |
| `_optional/master-account/identity-dnx-root-access.cf.yml`, `new-roles.yaml`, `dnx-access-readonly.yml`, `dnx-api-access-simple-v3.cf.yaml` | management | **DNX access roles** into our accounts (admin, read-only, security, DB). Skip unless we deliberately grant DNX access |

---

## 4. What gets created when everything is on (cost-relevant)

Prices are rough and from memory, so **check the AWS pricing pages before committing**.

| Thing | Notes |
|---|---|
| **NAT Gateway** | Roughly US$30–35/month *each* plus data charges. The `network` stack turns one on per environment by default (`nat = true`). This is the biggest silent cost of the kit. We do not need it for a serverless platform |
| **GuardDuty, Security Hub, Config** | Usage-based. Small at our size, but Config is billed per recorded change and can surprise |
| **KMS keys** | About US$1/month each. The security stack makes several (CloudTrail, Config, GuardDuty, plus `rds`/`backup`/`s3` CMKs in workloads) |
| **CloudTrail** | First management-event trail per account is free; extra trails are not. The security stack makes one per account, so watch for duplicates with the organisation-level one |
| **Client VPN, Transit Gateway, EKS, ECS, RDS, ElastiCache** | Real money every hour they exist. The sample `stage` workspace turns on ElastiCache and a lot more. Do **not** copy those sample workspaces blindly |
| **S3 log storage** | Small and cheap, but grows forever unless lifecycle rules run (they do: IA at 30 days, Glacier at 90) |

---

## 5. Our proposed account layout

You asked for: **prod, dev, beta, management, security/logs, and the master.**

**How I read your answers (updated 2026-10-23, please confirm in §10):**

- **"Master" = the management account.** DNX's own docs call it "Master" (`Architecture.Accounts.md`). It is a **brand-new account**, so the Organization starts clean.
- **"Security/logs" = two accounts** (audit + log-archive). The kit is built that way, and keeping them apart is the standard advice.
- **"Beta" = the kit's `stage`.**
- **Prod = the existing account `478043880000`, where the IoT platform lives.** It is **imported**, not created. There is **no new empty prod account**.
- **Legacy = a second, bigger existing account** (account ID not known to me yet). It is **imported as `legacy`**. Later, workloads move from `legacy` into `prod`.

So the end state is **6 new accounts + 2 imported accounts = 8**.

| # | Account | Kit name | New or imported | Why it exists | Stacks to deploy |
|---|---|---|---|---|---|
| 1 | **Management ("master")** | `root` | **New** | Owns the Organization, billing, SCPs. **No workloads, ever.** | None by Terraform. CloudFormation only: identity-baseline + billing/alarms |
| 2 | **Security (audit)** | `audit` | **New** | Hub for GuardDuty and Security Hub. Read-only access for auditors | identity, security (**master**) |
| 3 | **Log archive** | `log-archive` | **New** | Holds the locked log buckets. Nobody runs anything here | identity, security (log buckets) |
| 4 | **Shared services** | `shared-services` | **New** | **Holds the Terraform state bucket**, CI roles, later the parent DNS zone | identity, security (member) |
| 5 | **Dev** | `dev` | **New** | Development | identity, security (member), backup |
| 6 | **Beta** | `stage` | **New** | Pre-production testing | identity, security (member), backup |
| 7 | **Prod (IoT)** | `prod` | **Imported** (`478043880000`) | The live tracker platform | identity, security (member), backup |
| 8 | **Legacy** | `legacy` | **Imported** (ID: ask) | The older, bigger account we are moving away from | identity, security (member). **Nothing else; we do not rebuild it** |

```
                    ┌────────────────────────────┐
                    │  Management ("master") NEW │   Organization, billing, SCPs
                    └─────────────┬──────────────┘
   ┌───────────────┬──────────────┼───────────────┬────────────────────┐
   ▼               ▼              ▼               ▼                    ▼
Security OU    Shared OU    Workloads-NonProd  Workloads-Prod       Legacy OU
┌──────────┐  ┌──────────┐   ┌─────┐ ┌──────┐   ┌──────────┐      ┌──────────┐
│ audit    │  │ shared-  │   │ dev │ │ beta │   │ prod     │◀─────│ legacy   │
│ log-     │  │ services │   └─────┘ └──────┘   │ (IoT)    │ move │ (bigger) │
│ archive  │  │ TF state │                      │ IMPORTED │ over │ IMPORTED │
└──────────┘  └──────────┘                      └──────────┘ time └──────────┘
 logs ──▶ log-archive      findings ──▶ audit         (no SCPs on the two imported accounts at first)
```

**Why I added shared-services.** The kit hard-codes the Terraform state bucket into an account called `shared-services` (`remote-state.hcl`). The docs say it can live in management instead, but a deploy role and state in management breaks "nothing runs in management". A shared-services account with no VPC and no NAT costs almost nothing.

### 5.0 Who creates the accounts? (answer: not this repo, we do, by hand)

**The kit does not create AWS accounts or the Organization.** I searched the whole repo: there is no `aws_organizations_account`, no OU resource, no `CreateAccount` call. The only mention is an optional IAM permission in `identity-dnx-root-access.cf.yml` that would let *DNX staff* create accounts for us. `accounts.hcl` is only a **list of IDs you type in after the accounts exist**.

So Phase 1 is manual. Two ways, same result:

| Way | How | Notes |
|---|---|---|
| **Console** | AWS Organizations → *Add an AWS account* → *Create an AWS account* | Simplest; fine for 5 accounts |
| **CLI** | `aws organizations create-account --email aws-micway+audit@micway.com.au --account-name audit --role-name OrganizationAccountAccessRole` | Same thing, scriptable and repeatable |

Rules that apply either way:
- Each account needs a **unique root email address** (plus-addressing like `aws-micway+audit@…` works if all land in one mailbox).
- New accounts get a role called `OrganizationAccountAccessRole` that the management account can assume, which is how we first get in.
- Accounts are **hard to delete** (closing takes up to 90 days and they still count against the limit), so spell the names right the first time.
- New Organizations have a default cap on the number of accounts. 9 (management + 8) should fit, but check *Service Quotas → AWS Organizations*.
- Optional later: we *could* write Terraform that creates the accounts (`aws_organizations_account`). I do **not** recommend it: a mistaken `terraform destroy` would try to close accounts.

**What I left out, and why:**
- **`network-hub`**: it hosts a Transit Gateway joining many VPCs. We have no VPC fleet to join. Easy to add later.
- **central `backup` account**: useful once there is data worth copying across accounts. DynamoDB has PITR (CLAUDE.md: 35 days). Later phase.
- **`secure-prod`**: a stricter second prod. Not needed.
- **A new empty prod account**: not needed now that prod is an imported account.

### 5.1 The two imported accounts

Both accounts exist, are live, and were **not** built with this kit. Imported accounts need extra care that new ones do not.

**What is different about an invited (imported) account:**

1. **No `OrganizationAccountAccessRole`.** Accounts *created* in the Organization get it automatically; invited accounts do not. Log in to each directly once, deploy `identity-baseline` there, and make `TrustArns` include the management or shared-services deployer.
2. **Billing moves.** The new management account becomes the payer. Check the payment method, Savings Plans, Reserved Instances, credits and support plan first. Each account must **leave its old Organization** (if any) before it can accept the invite.
3. **Each goes in its own OU with no SCPs at first.** `Workloads-Prod` for prod, `Legacy` for legacy. Add SCPs one at a time after testing (§9 items 5–7).
4. **Existing security tooling may already exist.** The kit's `aws_guardduty_detector`, `aws_config_configuration_recorder` and `aws_cloudtrail` fail with "already exists" if one is there. Check first (commands below).
5. **Region check before the region SCP.** Prove which regions each account really uses, not which ones you think.
6. **They enter the kit the same way new accounts do:** add the ID to `accounts.hcl`, `organization.members` (audit) and `log_buckets.allow_from_account_ids` (log-archive); then apply identity, log-archive, audit, then the account's own `security` workspace.

**Discovery before the import (read-only, safe to run now).** Run once per account with that account's credentials:

```bash
# Is it already in an Organization, and is anything security-related already on?
aws organizations describe-organization
aws guardduty list-detectors --region ap-southeast-2
aws configservice describe-configuration-recorders --region ap-southeast-2
aws cloudtrail describe-trails --region ap-southeast-2
aws securityhub describe-hub --region ap-southeast-2

# Which regions and services is it REALLY using? (last 90 days of cost, grouped)
aws ce get-cost-and-usage --time-period Start=2026-07-23,End=2026-10-23 \
  --granularity MONTHLY --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=REGION --group-by Type=DIMENSION,Key=SERVICE

# Humans and keys that exist today (the Security Hub CIS checks will flag the bad ones)
aws iam generate-credential-report && aws iam get-credential-report
```

**Prod (`478043880000`, the IoT account).** Live production with real trackers. Details from CLAUDE.md that matter here:
- All five CDK stacks pin `env.account`; the account ID does not change on import, so nothing breaks there.
- CDK keeps owning the application. The landing zone adds the *security and account* layer around it, never the app.
- IAM user `fota_test` has access keys and no SSO. CIS controls in Security Hub **will** flag it. That is expected; plan to replace it with SSO later, not on day one.
- The region SCP allows only `ap-southeast-2` plus global services. IoT Core, Lambda, DynamoDB, Step Functions, API Gateway, Cognito and the AU SMS number are all there. **Check**: does any CDK stack use `us-east-1` (cross-region references, Lambda@Edge, CloudFront certificates)? CloudFront/ACM/WAF are exempt, but Lambda in `us-east-1` is not.
- CLAUDE.md warns that the CDK `dev` stage deliberately has an **empty account** so a dev stage can never double-ingest into prod. The new `dev` account is the first place that stage can legitimately get an ID. Do that on purpose and only then.

**Legacy (bigger account, ID not known to me).** I know nothing about what runs there, so the first job is discovery (above). Treat it as a **monitored holding area**:
- Enrol it in the **detective** controls first (CloudTrail, GuardDuty, Security Hub, Config) so we can see what it is doing.
- Do **not** attach the audit-lock SCP until its security tooling is in place (that SCP forbids changing GuardDuty).
- Do **not** run network, platform or backup stacks in it. We are moving out, not rebuilding.

### 5.2 Moving work from legacy to prod

The kit does not do this; it only makes it safer. Being in the same Organization helps because:
- one **log and findings pipeline** covers both, so we can see the move happen;
- **cross-account roles** and **AWS RAM** sharing let one side reach the other without long-lived keys;
- **Route53** in shared-services can own DNS, so cutover is a record change;
- snapshots, S3 buckets and databases can be **shared or copied between accounts in the same Organization** (RDS/EBS snapshot sharing, S3 replication, DMS).

A sensible shape: move **one service at a time**, prod and legacy running side by side, DNS cutover per service, then shut the legacy copy down. Keep a list in this folder (suggested file `LEGACY_MIGRATION.md`) with one row per service. Because I do not know what legacy contains, I cannot size this yet.

**One risk to name early:** both accounts have their own IAM, KMS keys and secrets. Encrypted data (KMS) does not move on its own; the key policy must allow the other account, or the data must be re-encrypted. Plan that per service.

---

## 5A. Security services we will enable

*(Numbered 5A so the other section numbers, which the rest of this document refers to, stay the same.)*

### 5A.1 How the security tools fit together

Think of five jobs. Each tool does one of them:

| Job | Question it answers | Tool |
|---|---|---|
| **Record** | "Who did what, and when?" | **CloudTrail** (every API call), **AWS Config** (every change to every resource) |
| **Detect** | "Is something bad happening right now?" | **GuardDuty** (threat detection), **IAM Access Analyzer** (accidental public/cross-account access) |
| **Judge** | "Are we set up securely?" | **Security Hub** (collects findings and scores us against CIS and AWS best practices) |
| **Protect** | "Make the bad thing impossible" | **SCPs**, S3 Block Public Access, EBS encryption by default, KMS, MFA |
| **Recover** | "Can we undo it?" | **AWS Backup**, DynamoDB PITR, S3 versioning |

**Example of them working together:** someone's access key leaks and is used from another country. CloudTrail records every call; GuardDuty notices the unusual location and raises a finding; Security Hub shows that finding next to the "IAM user has an old access key" control we already failed; the audit account's SNS topic emails us. Config shows exactly which resources the attacker changed.

### 5A.2 What the kit turns on (and how)

| Service | Kit setting | Where | What I would do |
|---|---|---|---|
| **CloudTrail** | `cloudtrail = { enabled = true, ... }`; 365-day CloudWatch log group; log file validation on; KMS-encrypted; the master creates the KMS key, members reuse it | Every account | ✅ Enable. **Management events only** (no data events, which is a decision already on record in `tracking/CLAUDE.md`, 2026-09-16: do not re-propose). Consider one **organisation trail** instead of nine per-account trails (cheaper and members cannot switch it off). Do not run both |
| **GuardDuty** | `guardduty = { role = master/member }`. Audit is the hub; members accept an **invitation**. Findings are exported to the log-archive bucket | Every account | ✅ Enable. The kit creates a *plain* detector (`enable = true`). Which optional "protection plans" are on depends on current AWS defaults. After deploying, **check** with `aws guardduty get-detector` and decide each one (table 5A.4) |
| **Security Hub** | `securityhub = { subscriptions = { cis = true, foundational = true, pci = false } }` | Master in audit; member elsewhere | ✅ Enable CIS + AWS Foundational. Leave PCI off (we do not process card data per anything I have seen; correct me). The CIS **version** is chosen inside DNX's module (1.1.0); check which one after deploy |
| **AWS Config** | Recorder for all supported resource types, 3-hourly snapshots, KMS-encrypted delivery to log-archive. **No Config rules** are created | Every account | ✅ Enable, because Security Hub's controls read from it. Watch cost in month one (recording is billed per configuration change; prod has many Lambda/Step Functions/IoT changes) |
| **EBS default encryption** | `ebs_encryption_by_default` | Every account | ✅ Enable (free, no downside) |
| **KMS keys** | CloudTrail, Config and GuardDuty keys; optional `kms_cmk` list | Audit; optional elsewhere | ✅ Keep the three service keys. Skip the optional `rds/backup/s3` CMKs in workloads until needed (about US$1/month each) |
| **IAM password policy / roles** | `iam_password_policy`, `aws_support_role`, `job_function_roles` | Every account | ✅ Password policy and Support role on. **Keep `job_function_roles` off**: with IAM Identity Center, permission sets create these roles for us |
| **Notifications (SNS), Chatbot** | `notifications`, `chatbot` | Audit | ✅ Email first, Slack later. **Test the alert path end to end** (see warning below) |
| **Auditor role** | `iam_role_auditor` | Audit | ⏳ Only when an external auditor needs it |
| **Detective** | `detective` | Audit | ❌ Off. Costs extra and we have nothing to investigate yet |

> **Warning: silent alerts.** The kit's SNS module is KMS-encrypted (`sns_kms_encryption = true`), and the GuardDuty rule targets a `chatbot-<channel>` topic. A topic that CloudWatch/EventBridge cannot publish to **looks fine and never alerts**. We hit exactly this class of failure on `micway-prod-alerts` on 2026-08-31 (CLAUDE.md). After Phase 5, force a test: create a sample GuardDuty finding (`aws guardduty create-sample-findings`) and confirm the email arrives.

### 5A.3 What the kit does **not** include but we should add

| Add | Why | Where | Effort |
|---|---|---|---|
| **IAM Identity Center (SSO) with MFA enforced** | Replaces long-lived IAM users and keys. The kit assumes it but does not create it | Management, then every account | Console, about an hour. See Phase 1b |
| **S3 Block Public Access (account level)** | Stops an accidental public bucket in any account. The kit only *protects the setting* with an SCP; it never sets it | Every account | One CLI call or a few Terraform lines per account |
| **IAM Access Analyzer (organisation analyzer)** | Free for external-access findings. Catches a role or bucket shared with an unknown account (relevant during the legacy move) | Audit as delegated admin | Small |
| **AWS IoT Device Defender: Audit** | Prod is an IoT account. Its audit checks include expiring or **shared device certificates**, over-permissive IoT policies, and unused CA certs, which touches exactly the two-certificates-one-truck problem in CLAUDE.md. Priced per device; at tens of devices it should be small. Check pricing | Prod only | Small. Console or CDK |
| **Billing budget + cost anomaly detection** | A leaked key usually shows up as a bill first | Management (`billing.cf.yml`, us-east-1) | Template exists |
| **CloudTrail CIS alarms** (root login, no-MFA login, IAM policy change, trail/Config change, CMK deletion, unauthorised calls) | Real-time email for the dangerous few events | Management (`cloudtrail-alarms-enhanced.cf.yml`) | Template exists |
| **AWS Health notifications / Trusted Advisor email** | Cert expiry notices, deprecations, security warnings from AWS itself | Management | Console |
| **Root user hygiene** | Hardware or authenticator MFA on all 8 roots, no root keys (SCP blocks them), emails to a group mailbox | Every account | Manual checklist |

### 5A.4 GuardDuty "protection plans": decide per feature

GuardDuty has optional add-ons. I do not know which the kit's plain detector enables, so check, then use this table:

| Protection | What it watches | Relevant to Micway? | Decision |
|---|---|---|---|
| **CloudTrail / DNS / VPC flow** (the basic engine) | API calls, DNS lookups, network flows | Yes | ✅ Always |
| **S3 Protection** | S3 data access patterns | Yes. FOTA/config files sit in S3 | ✅ On in prod, legacy |
| **Lambda Network Activity Monitoring** | Network calls made by Lambda functions | Yes. Prod is mostly Lambda | ✅ On in prod; watch cost |
| **Malware Protection for S3** | Scans new objects for malware | Only if people upload files via the portal (the `.cfg` upload does) | ⏳ Consider for the upload bucket only |
| **EKS audit logs / Runtime Monitoring (EKS, ECS, EC2)** | Kubernetes and container behaviour | No EKS/ECS/EC2 in prod. Legacy: unknown | ❌ Off for now; revisit after legacy discovery |
| **RDS login events** | Odd logins to Aurora/RDS | Prod: no RDS. Legacy: unknown | ⏳ After discovery |
| **Malware Protection for EC2 (EBS scans)** | Scans volumes when a finding fires | Legacy: depends | ⏳ After discovery |

### 5A.5 Other AWS security services, and my call

| Service | What it does | Call |
|---|---|---|
| **Amazon Inspector** | Scans Lambda functions and container images for known vulnerable packages | ✅ **Recommended in prod.** Lambda is our main compute, so this is the one most likely to find something real. Cost scales with function count; check pricing |
| **Amazon Macie** | Finds personal data in S3 | ❌ Skip until we know where driver/customer data sits |
| **AWS WAF** on API Gateway/CloudFront | Blocks bad web traffic to the portal and API | ⏳ Worth doing for the portal. The kit's WAF module lives in the `platform` stack we are skipping, so add it in CDK next to the API |
| **Shield Advanced, Firewall Manager, Network Firewall** | DDoS, org-wide firewall policy, network inspection | ❌ Skip. Expensive for our size; the `expensive-services` SCP blocks Shield Advanced anyway. Shield Standard is automatic and free |
| **AWS Backup + Vault Lock** | Immutable backups | ⏳ Phase 7. Vault Lock is blocked by the `expensive-services` SCP, so we must decide on purpose (§9 item 7) |
| **S3 Object Lock on log-archive** | Makes logs impossible to delete or edit, even by an admin | ⏳ Strongly worth it for a log archive. The kit does not set it and the SCP blocks the API, so this needs a deliberate exception |
| **Resource control policies / declarative policies (AWS Organizations)** | Org-wide rules on *resources* (for example "no public EBS snapshots"), complementing SCPs, which only restrict *people and roles* | ⏳ Worth a look later. I have not verified the current option set; check the AWS docs first |
| **AWS Security Hub cross-region aggregation** | One view across regions | ❌ Not needed: we operate in one region |

### 5A.6 What goes where (summary)

| Account | Security services |
|---|---|
| **Management** | CloudTrail alarms (CIS), Budgets, cost anomaly, Health. Organisation trail (if we choose it). SCPs live here. **No GuardDuty/Config needed beyond the org baseline** |
| **Audit** | GuardDuty master, Security Hub master, Access Analyzer admin, notification SNS/Chatbot. Optional auditor role |
| **Log archive** | Log buckets only (CloudTrail, Config, GuardDuty, access logs). Object Lock decision |
| **Shared services** | CloudTrail, GuardDuty (member), Security Hub (member), Config |
| **Dev / Beta** | Same members. Lower alert noise (alarms off, §9 item 13 style) |
| **Prod (IoT)** | Members + Inspector for Lambda + GuardDuty S3 and Lambda protections + **IoT Device Defender Audit** |
| **Legacy** | Members first (detective only). Protection plans after discovery |

### 5A.7 Expect findings on day one

The first Security Hub run on prod and legacy will show a long list. That is normal. Some will be:
- IAM user `fota_test` with access keys and no MFA (prod);
- root account MFA and key checks;
- S3 buckets without access logging or versioning;
- unencrypted or non-versioned resources created before the baseline.

Triage once, **suppress with a written reason** anything we accept, and only then turn on Slack/email for *new* high and critical findings. Turning on alerts before triage trains people to ignore them.

---

## 6. What to deploy, and what to skip

| Piece | Deploy? | Reason |
|---|---|---|
| IAM Identity Center (SSO) | ✅ management, first | Not in the kit as code; set up by hand (Phase 1b) |
| CloudFormation `identity-baseline` | ✅ every account | The doorway for Terraform |
| CloudFormation `terraform-backend` | ✅ shared-services | The state bucket |
| `identity` stack | ✅ every account | Roles, password policy, OIDC for GitHub. Imported accounts get it after Phase 8 |
| `security` stack | ✅ audit, log-archive, and all member accounts, including prod and legacy once imported | The core value of the kit |
| SCPs | ✅ but **last**, and edited first (§9) | Guardrails |
| Billing + budget template | ✅ management | Cheap protection from a surprise bill |
| `backup` stack | ⏳ later | Once there is stateful data worth copying across accounts |
| `dns-delegation` | ⏳ only if we want per-environment subdomains from one parent zone | |
| `network` stack | ❌ for now | We have no VPC workloads. A serverless IoT platform needs no VPC or NAT |
| `platform`, `platform-data` | ❌ | ECS / EKS / RDS. Micway is on CDK + Lambda + DynamoDB |
| Client VPN / OpenVPN / Transit Gateway | ❌ | No use for them today |
| `security-baseline.cf.yml` | ❌ | Duplicates the Terraform security stack |
| DNX access roles (`*DNXAccess`, `new-roles.yaml`, …) | ❌ unless contract says otherwise | See §9 item 1 |

---

## 7. Step-by-step plan

> Every phase ends with a check. Do not start the next phase until it passes.

### Phase 0 — Decisions and tools (no AWS changes)
1. Answer the questions in §10.
2. Install: **Terraform ≥ 1.6** (the runbook says 1.5, but `remote-state.hcl` uses a nested `assume_role` block in the S3 backend, which I believe needs 1.6 or newer; verify with `terraform init`), Terragrunt, AWS CLI v2.
3. Agree the email scheme: one **unique root email per account**. The kit assumes `aws-micway+audit@micway.com.au`-style plus-addresses (they all land in one mailbox). Put root MFA on every account.

### Phase 1 — Organization and accounts (console, by hand)
1. In the **management** account: create the Organization, enable all features.
2. Create OUs: `Security`, `Shared`, `Workloads-NonProd`, `Workloads-Prod`, `Legacy`.
3. **Create** 5 new accounts: audit, log-archive, shared-services, dev, beta. **Do not touch `478043880000` (prod) or the legacy account yet.** They are imported in Phase 8, after the baseline works.
4. Write the 7 known account IDs (6 new + prod) into `_workspaces/accounts.hcl` (prod's is `478043880000`). Leave `legacy` out until Phase 8. Create the `legacy` workspace folders then (copy `dev`'s `identity` and `security`, nothing else).
5. **Set up SSO in Phase 1b, right after this**, so nobody ever needs an IAM user or root login for day-to-day work.
✅ *Check:* `aws organizations list-accounts` shows management + the 5 new accounts, all `ACTIVE`.

Meanwhile, **run the read-only discovery commands in §5.1 against prod and legacy.** It costs nothing and does not touch them.

### Phase 1b — SSO (IAM Identity Center): how people log in

**What it is, plainly:** one login page (`https://<yourname>.awsapps.com/start`) where each person signs in once, with MFA, and then picks an account and a role from a list. No IAM users, no access keys on laptops. AWS creates the roles in every account for us. **The kit assumes this exists but does not set it up** (it only ships an optional Google Workspace sync, below).

1. In the **management** account, open IAM Identity Center and **enable it**. Pick the **home region deliberately** (`ap-southeast-2`); it is awkward to change later.
2. **Identity source.** Decide where users live:
   - *Identity Center's own directory* (simplest; we create users by hand), or
   - an **external identity provider** (Google Workspace or Microsoft Entra ID). The kit's optional `ssosync` module (a Lambda that copies Google users and groups into Identity Center every 24h, `identity/ssosync.tf`) only helps for **Google Workspace**. It is **not enabled** in any workspace today.
3. **Create groups**, not individual assignments: `Admins`, `Developers`, `ReadOnly`, `Billing`, `Auditors`, `InfraDeploy`.
4. **Create permission sets** (a permission set is a template for the role AWS creates in each account):

   | Permission set | Based on | Used by |
   |---|---|---|
   | `AdministratorAccess` | AWS managed | `Admins`, short sessions |
   | `PowerUserAccess` | AWS managed | `Developers` on dev/beta |
   | `ReadOnlyAccess` | AWS managed | `ReadOnly`, and `Developers` on prod |
   | `SecurityAudit` | AWS managed | `Auditors`, on audit and log-archive |
   | `Billing` | AWS job-function | `Billing`, management only |
   | `InfraDeploy` | custom inline: allow `sts:AssumeRole` on `arn:aws:iam::*:role/InfraDeployAccess` and `…/TerraformBackendAccess` | whoever runs Terraform |

5. **Assign** group × permission set × account. Example: `Developers` → `PowerUserAccess` → dev, beta; `Developers` → `ReadOnlyAccess` → prod; `Admins` → `AdministratorAccess` → all (consider requiring approval for prod).
6. **Turn on MFA** (Settings → Authentication → *Every time they sign in*), and set sessions to about 8 hours.
7. **Create at least two admin users** and test each one logs in and reaches every account.
8. **Use it from the terminal:**
   ```bash
   aws configure sso            # one profile per account, e.g. micway-dev
   aws sso login --profile micway-dev
   AWS_PROFILE=micway-dev terragrunt plan
   ```
9. **Connect it to Terraform.** The `InfraDeployAccess` role must trust the SSO role. Put the SSO `InfraDeploy` role's ARN (or, as a fallback, the shared-services account ID) in `TrustArns` in Phase 2. **I have not verified how IAM treats the path in SSO role ARNs (`/aws-reserved/sso.amazonaws.com/...`) inside a trust policy.** Test it in the first account before repeating it in all of them, and if the ARN is refused use the account ID and let the permission set's own policy do the narrowing.
10. **Keep a break-glass path.** Root credentials plus a hardware MFA key for management, stored offline, and a second admin person who can reach them. SSO lives in management, so if management is locked out, everything is.

**Why this comes before the bootstrap:** the Phase 2 templates need to know *who* may deploy (`TrustArns`), and that answer is "the SSO `InfraDeploy` role".

**For the two imported accounts (Phase 8):** once they join the Organization, Identity Center creates its roles in them automatically. That means we can reach them with SSO `AdministratorAccess` instead of hand-building an access role. This removes the "no `OrganizationAccountAccessRole`" problem from §5.1, which I wrote before SSO was in the plan.

**Later, not now:** the repo's CLAUDE.md says every command uses the `micway` profile for IAM user `fota_test`. After SSO exists, that moves to an SSO profile for the prod account and `fota_test` can be retired. That is a change to how the existing project is deployed, so do it deliberately, not as part of the landing zone.

### Phase 2 — Bootstrap CloudFormation (console, by hand, **in each of the 6 new accounts**)
1. In **each** of the 5 new workload/security accounts, and in management (management needs the roles too, so the deployer can reach it): deploy `identity-baseline.cf.yml` with `OrgName=micway`, `DNX=false`, `DNXAutomation=false`, `TrustArns=<who will run Terraform>`.
2. In **shared-services**: deploy `terraform-backend.cf.yml` with `OrgName=micway`, `RoleARNs=` the `InfraDeployAccess` ARN of every account that exists so far (the 6 new ones). **Prod and legacy are added in Phase 8** by updating this stack's parameter, `CitadelAutomation=false`.
3. In **management** (region **us-east-1**): deploy `billing.cf.yml` with a budget and anomaly detection.
✅ *Check:* from your shell, `aws sts assume-role` into `InfraDeployAccess` works in each new account, and `aws s3 ls s3://micway-terraform-backend` works through `TerraformBackendAccess`.

### Phase 3 — Identity stack (Terraform)
```bash
cd _workspaces/<account>/ap-southeast-2/identity
terragrunt init && terragrunt plan     # read the plan; look for anything you do not recognise
terragrunt apply
```
Order does not matter between accounts. Turn on `oidc` here so GitHub Actions can take over from your laptop afterwards. **First fix the repo name** (§9 item 2).

### Phase 4 — Log archive (Terraform)
```bash
cd _workspaces/log-archive/ap-southeast-2/logs && terragrunt apply
terragrunt output      # must show cloudtrail_s3_bucket_name, guardduty_s3_bucket_name, config_s3_bucket_name
```
Every account ID must already be in `log_buckets.allow_from_account_ids`, or that account's CloudTrail will be refused later.

### Phase 5 — Security: audit first, then members
```bash
cd _workspaces/audit/ap-southeast-2/security && terragrunt apply     # the "master"
for acct in shared-services dev stage; do
  (cd _workspaces/$acct/ap-southeast-2/security && terragrunt apply)   # the "members"
done
```
The audit workspace must already list the members in `organization.members` (GuardDuty sends the invites). Prod and legacy are added in Phase 8.
✅ *Check:* Security Hub in the audit account shows all member accounts; GuardDuty shows them as "Enabled"; CloudTrail files appear in the log-archive bucket within about 15 minutes.

### Phase 6 — Guardrails (SCPs) — last, and tested
1. Attach the SCPs to a throwaway **test OU** first (the new `dev` account works as the target).
2. Prove that a normal deploy, a `terragrunt apply` on security, and a CDK deploy all still work.
3. Then `Workloads-NonProd`. **`Workloads-Prod` and `Legacy` come last and only after Phase 8**, and one SCP at a time (region lock → expensive-services → audit lock).

### Phase 7 — Later (backup, DNS, delegated admin)
`backup` stack and a central backup account; `dns-delegation`; switch to delegated-admin GuardDuty/Security Hub; fill in Chatbot/Slack.

### Phase 8 — Import the two existing accounts (only after Phase 6 is stable on the new accounts)

**8a. Prod (`478043880000`, the IoT account) first.** It is small, well understood (CLAUDE.md) and CDK-driven.
1. Run the §5.1 discovery commands again, and confirm it is not in another Organization (or leave it).
2. Invite it from the management account; accept in prod. Move it to `Workloads-Prod` (**no SCPs yet**).
3. Deploy `identity-baseline` in it (`DNX=false`, `DNXAutomation=false`). Use SSO `AdministratorAccess` once Identity Center has provisioned its role; if that is not ready yet, log in directly, because no `OrganizationAccountAccessRole` exists in an invited account.
4. Add `478043880000` to `organization.members` (audit) and `log_buckets.allow_from_account_ids` (log-archive). Apply log-archive → audit → `prod` identity → `prod` security.
5. Turn on prod-specific tools (§5A.6): Inspector for Lambda, GuardDuty S3 and Lambda protections, IoT Device Defender Audit.
6. Check an onboarding still works end to end, using the bench unit `865124073550719` per CLAUDE.md. Nothing in this phase touches the CDK stacks, but verify with `scripts/verify-deploy.ts`.
7. Triage the first Security Hub findings (§5A.7). Only then add SCPs, one at a time.

**8b. Legacy second.** The discovery results decide the rest.
1. Same invite / identity-baseline / member-list steps, into the `Legacy` OU.
2. **Detective controls only.** Run the legacy `security` workspace so we can see what is happening there. No network, platform or backup stacks.
3. Fix "already exists" conflicts first (an existing GuardDuty detector, Config recorder or trail) by importing them into Terraform or disabling them.
4. Write `LEGACY_MIGRATION.md` (see §5.2) with one row per service to move to prod. Move one service at a time.
5. SCPs last, tested against what the cost report shows it really uses.

---

## 8. Recommendations (beyond "run what DNX gave us")

1. **Use delegated administrator, not invitations, for GuardDuty and Security Hub.** AWS Organizations can auto-enrol every new account. The kit's invite model needs a manual list and a two-step apply for each new account. It works, but it is the thing most likely to be forgotten.
2. **Prefer an organisation-level CloudTrail** (one trail for the whole org, created in management, writing to the log-archive bucket) over per-account trails. It is cheaper and a member admin cannot switch it off. The kit supports per-account only; both can coexist, but then you pay for the second trail.
3. **Set up SSO (IAM Identity Center) and avoid long-lived IAM users.** Today `fota_test` is an IAM user with access keys. The kit's own docs say "no IAM users, use SSO".
4. **Turn on S3 Block Public Access at account level** in every account. Nothing in the kit does this (the SCP only protects the *settings*).
5. **Keep Micway's CDK platform separate.** The landing zone is the *foundation*; CDK keeps deploying the application. Do not port the CDK stacks to Terraform.
6. **Cost guardrails day one:** budget alert (the billing template) plus a budget per workload account, tagged by `global_tags`.
7. **Document break-glass.** Where are the root credentials and MFA devices for each of the 8 accounts, and who can open them? The SCP blocks the root user in member accounts, which is good, but recovery needs a plan.
8. **Re-use our existing rule from CLAUDE.md:** account IDs must be pinned. Keep `env.account` pinned in every CDK stack, and put the matching ID in `accounts.hcl`.

---

## 9. Problems I found in the kit (fix before use)

I checked each of these in the files; where I am not sure, I say so.

1. **DNX gets full admin in every account by default.** `identity-baseline.cf.yml` has `DNX` and `DNXAutomation` both defaulting to `"true"`. That creates a role `{OrgName}DNXAccess` trusted by DNX's AWS account `148642451802`, and it also puts DNX's automation role `arn:aws:iam::953027019050:role/InfraDeploy` in the trust of `InfraDeployAccess`. Both roles carry `Action: "*" / Resource: "*"`, and the backup template has a similar `CitadelAutomation` flag, also defaulting to true. **Anyone who controls those DNX accounts could do anything in ours.** Set all three to `false` unless a contract requires it, and if it does, get it written down and scoped (the `dnx-access-readonly.yml` template shows the read-only alternative).
2. **Leftovers from other DNX customers.**
   - `bemoved-aws-iac` is the GitHub repo name in the OIDC roles of audit, dev, stage, prod and secure-prod identity workspaces.
   - `platform-data/bucket.tf:18` points S3 access logging at `bemoved-log-archives-s3-access-logs-…`.
   - `_scp-policies/audit-security-lock.json` protects `firefront-audit-*`, i.e. **someone else's bucket pattern**, so it would protect nothing of ours. Ours would be `micway-log-archive-*`.
   - `audit/security` has a Slack workspace note `TH8BC35NJ <- DNX workspace`.
3. **`shared-services` network config will not even parse.** It reads `vpc_cidrs.shared-services` and `vpc_cidrs.vpn-cidr`, which do not exist in `environments.hcl`. (Not a problem if we skip the network stack.)
4. **`network-hub` is referenced but has no workspace.** The audit and log-archive configs reference `accounts.network-hub`, so if we remove it from `accounts.hcl` we must also remove those references, otherwise Terragrunt fails.
5. **The audit-lock SCP locks out our own deployer.** It denies `guardduty:CreateDetector`, `UpdateDetector`, `CreateMembers`, `InviteMembers`, … for **everyone**, plus `cloudtrail:StopLogging/DeleteTrail` and Config recorder deletion. Once attached, `terragrunt apply` cannot change GuardDuty any more, and cannot replace a trail. The fix is the order in §7: build security first, attach this SCP last, and detach it for any later security change.
6. **The region SCP list will block things we may use.** `BlockedRegions` in the CloudFormation template is actually the **allowed** list (confusing name). The kit also uses `us-east-1` for ACM (CloudFront certificates) and as the backup secondary region; ACM is exempt but **AWS Backup is not**, so cross-region backup to `us-east-1` would fail unless we allow that region. `scp-region.json` has `"ArnNotLike": { "aws:PrincipalARN": [] }`, an **empty** exemption list, which may be rejected by AWS or may do nothing. Verify when we create it.
7. **The "expensive services" SCP blocks things we may want.** It denies Route53 domain registration/transfer, S3 object lock, Glacier vault lock and **AWS Backup Vault Lock**. Backup Vault Lock and S3 Object Lock are exactly how you make logs and backups undeletable, so this SCP and the advice in §8 fight each other. Decide on purpose.
8. **Naming mismatches across docs and code.** The docs describe buckets as `…-audit-cloudtrail-…`; the Terraform actually creates `{org}-{account_name}-cloudtrail-{region}`, so ours will be `micway-log-archive-cloudtrail-ap-southeast-2`. The CloudFormation `security-baseline` writes to `…-audit-cloudtrail-…` instead. The runbook calls the logs step a "logs stack", but it is really the `security` stack run in the log-archive account (the workspace folder is named `logs`).
9. **Missing management-account workspace.** The runbook says management gets "Identity", but there is no `_workspaces/root/`. Management is CloudFormation-only in this kit.
10. **CI workflow lists accounts and stacks that do not exist** (`qa`, `demo`) and omits `secure-prod`, `root`, `network-hub`. It authenticates with `role/InfraDeployGitHub`, which only exists once the OIDC block is enabled in identity, so the **first** runs must be from a laptop.
11. **Doc paths are out of date.** The docs refer to `_cf-templates/all-accounts/…`, `_cf-templates/shared-services/…`, `audit/one.yaml` and `_docs/templates`, none of which exist in this copy. The runbook and the files disagree in small ways; trust the files.
12. **Config delivery policy needs checking (not confirmed).** In `security/aws-config.tf` the IAM policy allows writes under `…/prefix/AWSLogs/<account>/*` while the delivery channel uses an empty prefix. That *may* be fine because the bucket policy does the real granting, but test Config delivery in Phase 5 and look for `AccessDenied` in CloudTrail.
13. **Cost trap in sample workspaces.** `stage/platform-data` turns on ElastiCache, `dev/platform` builds an ECS cluster with an ALB and an ECR repo called `hello`, and every `network` workspace creates a NAT gateway. If any of these are applied, we start paying immediately.

---

## 10. Questions I need you to answer

1. ~~Is "master" the management account?~~ Answered: a new account.
2. **Security and logs: one account or two?** I recommend two (audit and log-archive). One is simpler but weakens the separation.
3. **OK to add a `shared-services` account** to hold the Terraform state? (The alternative is the management account, which I recommend against.)
4. **Please confirm my reading of the two existing accounts:** `478043880000` (IoT) is imported as **prod**; a second, bigger account is imported as **legacy** and its workloads later move into prod. **What is the legacy account's ID**, what is it mostly running, and what is each account's current Organization and payer?
5. **Does DNX need any access to our accounts?** If their contract includes operations/support, which roles and with what scope?
6. **Domain name:** what do we want for `domain_patterns` (e.g. `micway.com.au`, `prod.micway.cloud`)? Do we need DNS in AWS at all for now?
7. **Who gets to run Terraform?** You alone, a small group, or only GitHub Actions? This decides `TrustArns` and the OIDC setup.
8. **Email addresses** for the 6 new accounts' root emails and for security alerts. (The two imported accounts keep theirs.)
9. **Slack:** do we want alerts in a Slack channel (Chatbot) or email only?
10. **Security services (§5A):** are you happy with the list? Specifically: org-level CloudTrail instead of per-account trails; Inspector for Lambda in prod; IoT Device Defender Audit in prod; S3 Object Lock on log-archive (needs an SCP exception); and PCI standard **off**. Do we hold any card data or personal data that would change that?
11. **SSO identity source:** where do Micway's staff accounts live today (Google Workspace, Microsoft 365/Entra ID, or none)? That decides whether we sync users (`ssosync` only fits Google) or create them by hand in Identity Center. Who are the 2 admins?
12. **Is the repo copy (`MicwayTransport/aws-landingzone-dnx`) ours to modify?** I would fix §9 items 2–4 and commit them on a branch, never on DNX's original.

---

## 11. Suggested next steps for me

If you confirm §10, I can, in this order and without touching AWS:
1. Create a branch in `aws-landingzone-dnx/` and fill in `globals.hcl`, `accounts.hcl` (placeholders until real IDs exist) and `environments.hcl`.
2. Remove the unused accounts/workspaces and the other-customer leftovers (§9 items 2–4), and set DNX access to off.
3. Rewrite the three SCPs for Micway (bucket pattern, allowed regions, backup/object-lock decision) and write a **test plan** for them.
4. Produce a one-page **runbook with the exact commands** for Phases 1–6, with the real account IDs.
5. Write the discovery results for prod and legacy into the doc once you run the §5.1 commands (or give me credentials to run them read-only, on your say-so).

I will not run `terragrunt apply`, create accounts, or attach SCPs without your explicit go-ahead.
