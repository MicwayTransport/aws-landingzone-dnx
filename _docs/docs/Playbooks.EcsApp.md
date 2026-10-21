# Playbook: Creating a new ECS App

## Platform Stack Changes

The Terraform Platform stack controls the creation of ECS Clusters and Services.

To create a new App, look for the key `ecs` and under it: `apps` and `workers`.

### Clusters

Before creating an app, make sure there is an ECS cluster to run the app.

For the 2 application types we use (apps and workers), we create a cluster for each one, as the example below:

```yaml
ecs:
  create_iam_service_linked_role: true
  clusters:
    - name: "dev-apps"
      fargate_only: true
      alb: true
      certificate: default
    - name: "dev-workers"
      fargate_only: true
      alb: false
  apps: [] # see below
  workers: []
```

The only difference between them is that workers cluster do not come with an ALB.

### Apps

Apps are web-based applications that use Load Balancer to serve traffic.

To add an app, create a new item in the list with the content:

```yaml
apps:
  - name: "realworld-api"
    cluster_name: "dev-apps"
    hostnames:
      - "realworld-api.dev.bubbletea.dnx.host"
    hostname_redirects: ""
    hosted_zone: dev.bubbletea.dnx.host
    hostname_create: true
    paths:
      - "/*"
    healthcheck_path: "/healthcheck"
    service_health_check_grace_period_seconds: 300
    cloudwatch_logs_export: false
    autoscaling_min: 1
    autoscaling_max: 4
    create_iam_codedeployrole: false
    launch_type: "FARGATE"
    fargate_spot: true
    memory: 512
    cpu: 256
    container_port: 8080
    auth_oidc:
      enabled: true
      paths: ["/admin*"]
      # hostnames: []
      authorization_endpoint: "https://accounts.google.com/o/oauth2/v2/auth"
      client_id: ""
      client_secret: ""
      issuer: "https://accounts.google.com"
      token_endpoint: "https://oauth2.googleapis.com/token"
      user_info_endpoint: "https://openidconnect.googleapis.com/v1/userinfo"
```

Some key elements of an ECS App:

#### Cluster Name

This parameter has to match the name of the ECS Cluster defined for the environment.

#### Hostnames

There are 4 parameters that control the creation and usage of hostnames for an ECS App.

`hostnames`: List of hostnames that this application uses.
This is added to the ALB Listener Rule as a filter to know that requests coming from those hostnames are routed to the application.

`hostname_redirects`: A comma-separated list of hostnames that redirect to the main hostname (first entry of `hostnames`).
One example would be to redirect the `www` domain to naked. (`www.myapp.com` -> `myapp.com`)

`hostname_create`: Tells the module to create the records in route53.

`hosted_zone`: The hosted zone name to create the hostnames (only used when `hostname_create: true`)

In production environments, you might see `hostname_create: false`. This is normal as the DNS record is created manually for the cutover and also because sometimes the hosted zone domain for production is different from non-production environments.

#### Scaling

Autoscaling is controlled by the parameters:
```
  autoscaling_min: 1
  autoscaling_max: 4
```

To disable autoscaling, set the same value for min and max.

#### Resources

Set the resources that will be available for the containers (tasks) with:

```
  memory: 512
  cpu: 256
```

These numbers have to follow the available for ECS Fargate. Not all combinations are valid. Please see [https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html#fargate-task-defs]() for the available combinations.

#### OIDC

This feature allows to protect an endpoint of your application using OIDC. This is useful for web applications to add an extra layer of protection for administrative URLs or non-production environments.

It's possible to protect endpoints based on hostnames or paths. For paths, always follow the pattern `/<endpoint>*` without a trailing slash, ending with a wildcard to capture all URLs that start with the pattern.

### Workers

Workers are applications that have the following characteristics:

* Do not listen on a port
* Runs jobs - cron based or queue/event based
* Have a fixed number of instances, can't autoscale

Example:

```yaml
workers:
  - name: "realworld-api-worker"
    cluster_name: "dev-workers"
    desired_count: 1
    cloudwatch_logs_export: false
    launch_type: "FARGATE"
    fargate_spot: true
    memory: 512
    cpu: 256
```

## Application Code Changes

We recommend following the 12-factor app methodology: [https://12factor.net/]().

Most important parts are:

### Keep your application stateless

Make sure user sessions are stored in the database or a cache instead of the file system.

The reason this is important is to allow the application to scale up or down without impact for users.

### Environment Variables

All parameters of your application that might change between environments must be defined as environment variables.

## Preparation

Copy the `.deploy` folder from another application into the new one.

Work on the `Dockerfile` to run your application with Docker.

Open the `Makefile` and update the variables at the top to match your application.

### The Task Definition File

Open the `task-definition.tpl.json` file.

List the environment variables needed by your application, for static variables it's ok to add under `environment` but be aware these variables won't change per environment. For the other variables, please add unser `secrets`, pointing to SSM Parameters or AWS Secrets Manager secrets.

Example:

```
"secrets": [
  {
    "name": "DB_HOST",
    "valueFrom": "arn:aws:ssm:${AWS_DEFAULT_REGION}:${AWS_ACCOUNT_ID}:parameter/rds/${ENVIRONMENT_NAME}-api/HOST"
  }
],
```

The variables `AWS_DEFAULT_REGION`, `AWS_ACCOUNT_ID` and `ENVIRONMENT_NAME` are replaced during the deployment and the final ARN must match an existing parameter.

If your application needs a special IAM role to run, update the `taskRoleArn` attribute with the role ARN.

For the list of all attributes supported by the task-definition, please see [https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html]().

## Environment Variables and SSM Parameters

TBC

## Deployments

TBC