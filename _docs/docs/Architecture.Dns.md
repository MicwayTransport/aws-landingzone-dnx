# DNS

The AWS Foundation stack has multiple AWS Accounts and each one has a Route53 Hosted zone, each environment (shared-service, non production and production) will have a valid DNS (Domain Name Service) entry and a valid SSL certificated managed by ACM (AWS Certificate Manager).

The stack controlling the network resources is the **Platform** stack.

The hosted zones per account are:

{%- set has_domains = namespace(found=false) %}
{%- for workspace_name, workspace in outputs.network.items() %}
{%- if not ('template' in workspace_name) and workspace.domain is defined and workspace.domain | length > 0 %}
{%- set has_domains.found = true %}
{%- endif %}
{%- endfor %}

{%- if has_domains.found %}
| Account | Domain | Name Servers |
| ------- | ------ | ------------ |
{%- for workspace_name, workspace in outputs.network.items() %}
{%- if not ('template' in workspace_name) and workspace.domain is defined %}
{%- for domain_name, domain in workspace.domain.items() %}
| {{ stacks.network.workspaces[workspace_name].account_name }} | {{ domain_name }} | {{ domain.name_servers |join(', ') }} |
{%- endfor %}
{%- endif %}
{%- endfor %}
{%- else %}

> **Note:** No Route53 hosted zones have been deployed yet. Domain information will appear here after running `terragrunt apply` in network stacks with domain configuration enabled.

{%- endif %}

In a standard DNS setup, a parent domain is hosted in a central account (typically shared-services or production), and subdomains are delegated to individual workload accounts.

{%- set has_dns_delegation = namespace(found=false) %}
{%- for workspace_name, workspace in outputs['dns-delegation'].items() if outputs['dns-delegation'] is defined %}
{%- if not ('template' in workspace_name) and workspace.delegated_zones is defined %}
{%- set has_dns_delegation.found = true %}
{%- endif %}
{%- endfor %}

{%- if has_dns_delegation.found %}

{%- for workspace_name, workspace in outputs['dns-delegation'].items() %}
{%- if not ('template' in workspace_name) and workspace.parent_zone_name is defined %}

**DNS Delegation Structure:**

Parent zone `{{ workspace.parent_zone_name }}` is hosted in the **{{ workspace_name.split('_')[0] }}** account and delegates to the following child zones:

| Parent Zone | Delegation Record | Record Type | Child Zone Name Servers |
| ----------- | ----------------- | ----------- | ----------------------- |
{%- for zone_key, zone_info in workspace.delegated_zones.items() %}
| {{ workspace.parent_zone_name }} | {{ zone_info.fqdn }} | NS | {{ zone_info.name_servers | join(', ') }} |
{%- endfor %}

This allows each workload account to have full DNS authority over its subdomain, while the parent zone maintains the delegation records.

{%- endif %}
{%- endfor %}

{%- else %}

As an example, if your infrastructure domain is `infra.mycompany.com`, the setup would look like:

**Shared Services (or Production) account:**
- `infra.mycompany.com` (parent zone)

**Workload accounts:**
- `dev.infra.mycompany.com` (dev account)
- `qa.infra.mycompany.com` (qa account)
- `stage.infra.mycompany.com` (stage account)
- `prod.infra.mycompany.com` (prod account)

{%- endif %}

Therefore, workload accounts have DNS authority controlled by the parent zone account.

So applications in nonprod would use the records:

* myapp.staging.cloud.mycompany.com
* myapp.dev.cloud.mycompany.com

While in production:

* myapp.prod.cloud.mycompany.com (before cutover)
* myapp.mycompany.com or mycompany.com (after cutover)


<!-- ![AWS DNS HLD](images/hld_aws_dns.png) -->

## DNS Delegation Stack

The **dns-delegation** stack automates the creation of NS (Name Server) delegation records between parent and child hosted zones across AWS accounts.

This stack is deployed in accounts that host parent zones (typically production or shared-services) and automatically creates NS records pointing to child zones in other accounts.

{%- set has_dns_delegation = namespace(found=false) %}
{%- for workspace_name, workspace in outputs['dns-delegation'].items() if outputs['dns-delegation'] is defined %}
{%- if not ('template' in workspace_name) %}
{%- set has_dns_delegation.found = true %}
{%- endif %}
{%- endfor %}

{%- if has_dns_delegation.found %}

### Deployed Delegations

{%- for workspace_name, workspace in outputs['dns-delegation'].items() %}
{%- if not ('template' in workspace_name) %}

**{{ workspace_name.replace('_', ' ').title() }}**

{%- if workspace.delegated_zones is defined %}
| Child Zone | Parent Zone | Name Servers |
| ---------- | ----------- | ------------ |
{%- for zone_name, zone_info in workspace.delegated_zones.items() %}
| {{ zone_name }} | {{ zone_info.parent_zone_name }} | {{ zone_info.name_servers | join(', ') }} |
{%- endfor %}
{%- else %}
No delegations configured in this workspace.
{%- endif %}

{%- endif %}
{%- endfor %}

{%- else %}

> **Note:** DNS delegation stack has not been deployed yet. Delegation information will appear here after running `terragrunt apply` in dns-delegation workspaces.

{%- endif %}