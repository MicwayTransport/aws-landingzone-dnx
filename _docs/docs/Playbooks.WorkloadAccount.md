# Playbook: Creating a Workload Account

## Create a New AWS Account

Login to your Master (aka Management) account using root credentials.

Follow the instructions to create a new AWS account under the Organization: [https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_create.html]().

Once the account is created, by default an AWS role called `OrganizationAccountAccessRole` is created that trusts the Master account.

Information on how to access the newly created account can be found here: [https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_access.html]().

## Deploying the Identity-Baseline IAM Roles

Follow the instructions at [Identity Stack](Stacks.Identity.md) to deploy the service roles that allows Terraform to be deployed.

## Deploying the Infrastructure

From the main Terraform repository, prepare the workspaces for the new account.

Starting with the security stack at: `./security`

Create the workspace file `_workspaces/<stack>/<account>/terragrunt.hcl` following the same name standard as the other workspaces.

Copy the parameters from another workspace found in the same file, reviewing and changing the values to fit this new account.

Apply Terraform following the instructions described in the README file from the same folder for the new workspace created.

Then move on to the next stacks, applying the same steps above for: 

* Security
* Identity
* Platform
* Kubernetes (when used)

In the order above.
