# Logs

Logs from EKS, ECS and Lambda applications are automatically sent to Cloudwatch Logs.

## Viewing Logs

Login to the AWS Console using a ReadOnly, PowerUser, SystemAdministrator or Administrator role and go to Cloudwatch.

Under Cloudwatch, click Logs and Log Groups.

Some common Log Group names from AWS services are:

| AWS Service | Log Group |
| ----------- | --------- |
| Lambda | /aws/lambda/(function name) |
| Glue | /aws/glue/jobs/(job name) or /aws/glue/crawlers or /aws/glue/sessions or /aws/glue/python-jobs/output |
| API Gateway | /aws/apigateway/(name) |
| Codebuild | /aws/codebuild/(build name) |
| EKS | /aws/eks/(cluster name)/cluster |
| ECS | /ecs/(cluster name)/(app name) (defined in the task definition) |

A list of all AWS services that send logs to Cloudwatch Logs can be found here: [https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/aws-services-sending-logs.html]()