# Terragrunt pipelines (plan / apply)

Copy the three files into the repository's `.github/workflows/` folder:

- `deploy.yaml` – manual trigger (`workflow_dispatch`): account, stack, region and mode (plan/apply)
- `terragrunt_plan.yaml` – reusable plan workflow
- `terragrunt_apply.yaml` – reusable apply workflow (uses `-auto-approve`, gated by an Environment approval)

## How it works

- `mode=plan`: runs `terragrunt plan` and prints it in the job summary.
- `mode=apply`: runs a plan first, then, only if the plan has changes, the `apply` job waits for a
  reviewer to approve the Environment `<account>-<stack>-apply`. The reviewer can read the plan in the
  plan job summary before approving. The apply re-evaluates the configuration (it does not apply the saved plan file),
  so very recent drift can still show up.
- `apply` is rejected (preflight fails) when started from any branch other than the default branch (`main`).

## Prerequisites

1. **Folder structure** (same as aws-landingzone-dnx): `_workspaces/<account>/<region>/<stack>/` containing the `terragrunt.hcl`.
2. **Repository variable** `AWS_ACCOUNT_IDS` (Settings > Secrets and variables > Actions > Variables), a JSON map of account name to 12-digit account ID:
   `{"dev":"111111111111","prod":"222222222222"}`. Placeholder or non-12-digit values make the pipeline fail on purpose.
3. **GitHub Environments** (create them *before* the first run, because GitHub auto-creates a missing Environment with no protection):
   - `<account>-<stack>-apply` (e.g. `dev-network-apply`): **Required reviewers** (this is the only approval gate before `-auto-approve`) and **Deployment branches = `main` only**.
   - `<account>-plan` (e.g. `dev-plan`): optional, but recommended to restrict **Deployment branches** to `main` (and PR branches if you want plans from them).
   - Region is not part of the Environment name, so one approval rule covers every region of that account/stack.
4. **AWS (in each account), using GitHub OIDC:**
   - Identity provider `token.actions.githubusercontent.com`.
   - Role `InfraDeployGitHub` (trusted by GitHub OIDC; only needs permission to assume the role below).
   - Role `InfraDeployAccess`, with the permissions Terraform needs. It must trust `InfraDeployGitHub`.
   - These are the defaults and can be changed with the `deploy-role-name` and `access-role-name` inputs.

## ⚠️ TODO before first use: OIDC is not configured yet

The OIDC roles are created by the `identity` stack (`oidc` block in `_workspaces/<account>/<region>/identity/terragrunt.hcl`).
In `account-template` it is still a placeholder and must be changed:

- `enabled = false` → `true` (after the first deployment of identity).
- `org = "ORGANIZATION"` → your GitHub organization.
- `repos = ["REPOSITORY_NAME"]` → this repository.
- **Check the `sub` claim format of this repository.** `identity/oidc.tf` trusts `repo:<org>/<repo>:*`. GitHub repositories created after
  2026-07-15 (or that opted in) use immutable subject claims such as `repo:<org>@<id>/<repo>@<id>:...`, which that pattern does not match.
  Also, `repo:<org>/<repo>:*` accepts any branch, PR or environment; tightening it to `...:environment:<name>` requires changing the `terraform-aws-vcs-oidc` usage.
- Fill the real account IDs in `_workspaces/accounts.hcl` (currently `PLACEHOLDER-*`).

## What to adjust in `deploy.yaml`

- The `account`, `stack` and `region` option lists (currently match the folders/stacks in aws-landingzone-dnx).

## Versions

Terraform (`1.9.5`, same as before) and Terragrunt (`0.62.2`) are pinned via inputs, and the Terragrunt binary is checksum-verified.
Note: aws-landingzone-dnx's own workflows use Terraform `1.14.4`; if a state was ever written by a newer Terraform, `1.9.5` will refuse to read it — change `terraform-version` if that happens.
The `--terragrunt-*` flags apply to Terragrunt versions before the 0.73 series. When upgrading Terragrunt, replace them with the new ones (`--iam-assume-role`, `--non-interactive`) and test.

## Optional tip

For plan, a read-only role can be used: pass `access-role-name` in the `plan` job of `deploy.yaml` (currently the same role as apply).
