{% set audit_account = stacks.security.workspaces.values() | first %}
# Audit

There's a separated AWS account to centralise security and compliance information. This account is called the Audit account.

Audit is a protected account, accessible only with a restricted, mostly read-only IAM role.

Resources hosted by this account are:

## S3 Buckets for Long-term Storage

All buckets are set with a policy for changing the storage class to Glacier after 90 days.
This policy is configurable at `audit/one.yaml` under the key `logs_buckets.transition_to_glacier_in_days`

### ALB Logs Bucket

Name format: `{{audit_account.organization.name}}-audit-alb-access-logs-<aws_region>`

Purpose: Receive ALB logs from other AWS accounts for long-term storage.

### Application Logs Bucket

Name format: `{{audit_account.organization.name}}-audit-logs-<aws_region>`

Purpose: Receive Application logs from Cloudwatch Logs exports for long-term storage.

### AWS Config Logs Bucket

Name format: `{{audit_account.organization.name}}-audit-config-<aws_region>`

Purpose: Receive logs from AWS Config from other AWS accounts for long-term storage.

### AWS CloudTrail Logs Bucket

Name format: `{{audit_account.organization.name}}-audit-cloudtrail-<aws_region>`

Purpose: Receive logs from CloudTrail from other AWS accounts for long-term storage.

### AWS GuardDuty Logs Bucket

Name format: `{{audit_account.organization.name}}-audit-guardduty-<aws_region>`

Purpose: Receive logs from GuardDuty findings from other AWS accounts for long-term storage.