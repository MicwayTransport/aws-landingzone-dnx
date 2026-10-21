# Security

This stack does not require any other stack.

This stack applies to all AWS accounts, but is different for the **Audit** account, where it sets the centralised control of security services for the other accounts.

This stack also deploy log-archive buckets for the **Audit** account, as we use this account as both a central hub for security services and its logs for long-term storage.

## Terraform Workspaces

One terraform workspace AWS Region should be defined for this stack.

The workspace names are the region names.

## Features

### SecurityHub

Enables SecurityHub and collect logs from member accounts defined.

### Auditor IAM Role

Deploys a role called Auditor that have limited access to the account allowing assigned auditors to view logs and compliance reports.

### GuardDuty

Enables GuardDuty.

### Log Buckets

Creates S3 Buckets to receive logs from other accounts.

### Chatbot

Enables AWS Chatbot.

### Notifications

Creates an SNS Topic and allow defined AWS accounts to send notifications to it.

The notifications are then sent to the email and/or slack endpoint defined.

### Access Logs Bucket

Creates S3 Buckets specific for ALB Access Logs and allows other accounts to send logs to.

### CloudTrail

Enables CloudTrail in the AWS account, with the option to alarm on common detections like lack of MFA and root login.

### Config

Enables AWS Config.

### ECS Encryption Policy

Sets a policy for EBS volumes in the account to come with encryption by default.