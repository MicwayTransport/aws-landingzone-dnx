# Monitoring

Monitoring of your platform is done with Cloudwatch.

Most of AWS services automatically publishes metrics into Cloudwatch. Alarms then can be created on top of those metrics.

## Notifications

Alarms are set to send notification to the SNS topic defined in the Platform stack for each workspace.

By default, an SNS topic is created in the Audit account, which sends notification to the email address set in that stack.

Alarms can be disabled in non-production environment to avoid noise.

## Pre-configured Alarms

Some Terraform modules used come with pre-configured alarms (threshold values are configurable):

### ECS Cluster

Terraform module: [https://github.com/DNXLabs/terraform-aws-ecs]()

#### ALB 500 Errors

More than 10 errors detected in a 5-minute interval.

#### ALB 400 Errors

More than 10 errors detected in a 5-minute interval.

#### ALB Latency (anomaly detection)

Uses the Anomaly Detection to alarm when the latency is outside the historical pattern. Useful to detect changes of customer behaviour or malicious attacks.

#### EFS Low in Credits

Credits dropped below 1TB (from a maximum of 2.31TB).

#### High CPU in the Autoscaling Group

CPU is over 80% across the whole cluster in a 2-minute interval - not applicable for Fargate clusters.

#### High CPU in the ECS Cluster

Similar to the CPU in Autoscaling but measured with the ECS metrics.

#### High Memory in the ECS Cluster

Over 80% memory is consumed across the whole cluster.

### ECS App

Terraform module: [https://github.com/DNXLabs/terraform-aws-ecs-app]()

#### Minimum Healthy Tasks

Usually defined to 1 in non-production and 2 in production environments, will alarm when the value is below this number. Useful to detect if the application is running without redundancy in production.

#### High CPU Usage

Alarms when the CPU usage for the group of tasks of the ECS Service is above 80%.

### RDS Databases

The alarms are configured by the Terraform module [https://github.com/DNXLabs/terraform-aws-db-monitoring]().

#### High Memory

RDS memory is over 80% in an interval of 10 minutes.

#### High CPU

RDS CPU is over 80% in an interval of 10 minutes.

#### Low Disk Space

RDS Disk space is below 1GB in an interval of 10 minutes.

#### Low CPU Credits

(Only for t3 and t2 instance types)

RDS is lower than 100 CPU credits