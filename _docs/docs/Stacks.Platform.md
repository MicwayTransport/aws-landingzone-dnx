# Platform

The platform terraform stack is responsible for deploying all the resources that are required to run your workloads.

This stack requires the following stacks:

* Audit
* Baseline
* Identity

This stack applies to AWS accounts of the **workload** type.

## Features

### Domain

Configures Route53 Hosted Zones.

### ACM

Creates and validates ACM SSL/TLS Certificates.

### Network

Controls the whole networking layer, including:

* VPC
* Subnets
* Network ACLs
* VPC Endpoints
* VPC Peering
* DB Subnet
* Internet Gateway
* NAT Gateway

### OpenVPN

Creates an OpenVPN server to be used to access the VPC.

### EKS

Creates EKS Clusters and Node Groups.

### ECS

Creates ECS Clusters (Fargate and/or EC2).

#### Apps

Creates ECS Services.

#### Workers

Creates ECS Services to be used as workers.

Worker servers differ from normal services by not having an ALB Target Group attached to the server and does not use CodeDeploy to handle deployments.

### Static Frontends

Creates a static frontend application hosted in an S3 Bucket with CloudFront as CDN.

### RDS

Creates RDS databases with optional backups and monitoring.

### ECR

Creates ECR Repositories for hosting Docker images for ECS and EKS.

### SSM

Defines SSM parameters plaintext (strings) or KMS-encrypted (secured_strings)

### Backups

Enables AWS Backups that automatically backs up resources tagged properly.

### Log Exporter

It's a lambda function that exports logs from Cloudwatch Logs to a defined S3 Bucket (usually in the Audit account).

Used for long-term storage of logs.

More info at [https://github.com/DNXLabs/terraform-aws-log-exporter/]()

### Gitlab Runners

Deploys Gitlab runners in EC2 to the environment.