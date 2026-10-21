# Terraform IaC

## Installation

Make sure Terragrunt and Terraform are installed

* Terraform: https://developer.hashicorp.com/terraform/install
* Terragrunt: https://terragrunt.gruntwork.io/docs/getting-started/install/

## Folder Structure

Folder        | Description
------------- | ----------------------------------------------------------------------------------------
_cf-templates | CloudFormation templates required for foundation.
_docs         | Documentation generation engine
_scp-policies | Service Control Policies to be applied to the AWS Organization
_workspaces   | Definition for each stack and environment
identity      | Identity stack, responsible for basic IAM role structure for AWS Accounts
network       | Network stack, builds VPC and other network services
platform      | Platform stack, container and compute services
platform-data | Platform Data stack, builds stateful services like RDS, elasticache, etc.
security      | Security stack, compliance and audit services such as cloudtrial, guardduty, etc.

## Running Terraform / Terragrunt

Enter the workspace folder for the stack and environment desired:

```
cd _workspace/platform/dev
```

Setup AWS credentials in your shell (see below)

If modules changed, initialize terraform with the command:
```
terragrunt init
```

Run a plan to detect any drifts or to preview changes to be done
```
terragrunt plan
```

Once sure, apply the changes with:
```
terragrunt apply
```

---
Any other Terraform commands can run with terragrunt by simply replacing the command from terraform to terragrunt, examples:
```
terragrunt state list
terragrunt import ...
terragrunt state rm ....
```

## AWS Credentials and Roles

Terragrunt is configured to assume a role called `InfraDeployAccess` (see `terragrunt.hcl` in each workspace)

This role is created by the `identity-baseline.cf.yml` stack that you can find in the `_cf-templates` folder.

Ways to run Terraform:

### Running from EC2

When an EC2 instance is used to build infrastructure, such as when using a CI agent, the role `InfraDeployEc2` should be attached to the EC2.
The role will then assume `InfraDeployAccess` in each of the AWS accounts to deploy infrastructure.

By default, `InfraDeployAccess` only trusts the local `InfraDeployEc2` role (same AWS account).

If your EC2 instance needs to deploy to multiple accounts, add the ARN of the `InfraDeployEc2` role into all identity-baseline stacks. This can be done by setting the parameter `TrustARNs` when deploying `identity-baseline.cf.yml`.

## Running from GitHub/Gitlab/Bitbucket

Use OIDC to run from a supported CI.
With OIDC, the role is created in AWS with a trust directly to a specific repository or organization.

OIDC roles are managed by the `identity` workspaces. See `_workspace/identity/<env>/terragrunt.hcl`.

## Running Locally

When running locally, your local role needs to be able to assume `InfraDeployAccess`.

A common setup is to create a `InfraDeploy` or `AdministratorAccess` role in your shared-services account and assign to your users.

Then add this role ARN as a Trust to the `InfraDeployAccess` in all accounts. This can be done by setting the parameter `TrustARNs` when deploying `identity-baseline.cf.yml`.

