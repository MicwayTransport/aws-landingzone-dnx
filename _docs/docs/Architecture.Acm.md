# ACM Certificates

ACM is a service provided by AWS that automatically manages SSL/TLS certificates.

Advantages of using ACM instead of managing own certificates are:

* The private certificate is never exposed or available for download
* It's free
* Automatically renews (only when in use, attached to an ALB, Cloudfront or API Gateway for instance)

And comes with some disadvantages:

* The private certificate is never available for download - this can be a disadvantage depending on the use case
* Can only be used with AWS services like ALB, Cloudfront and API Gateway
* Does not provide some features like Organizational Validation (OV) or Extended Validation (EV)

ACM can also be used to store certificates purchased elsewhere. You can easily import certificates into ACM and use like an AWS-generated certificate. The only drawback is that it will **not** renew automatically like the AWS ones.

## List of ACM Certificates per Account

{%- set has_certificates = namespace(found=false) %}
{%- for workspace_name, workspace in outputs.network.items() %}
{%- if not ('template' in workspace_name) and (workspace.acm_certificate is defined or workspace.acm_certificate_global is defined) %}
{%- if (workspace.acm_certificate and workspace.acm_certificate | length > 0) or (workspace.acm_certificate_global and workspace.acm_certificate_global | length > 0) %}
{%- set has_certificates.found = true %}

### Account {{ stacks.network.workspaces[workspace_name].account_name }} ({{ stacks.network.workspaces[workspace_name].aws_account_id }})

| Region | Name | Domains | ARN |
| ------ | ---- | ------- | --- |
{%- if workspace.acm_certificate is defined %}
{%- for certificate_name, certificate in workspace.acm_certificate.items() %}
| {{ stacks.network.workspaces[workspace_name].aws_region }} | {{ certificate_name }} | {{ certificate.dns_validation_records|map(attribute='domain_name') |join(',') }} | {{ certificate.arn }}
{%- endfor %}
{%- endif %}
{%- if workspace.acm_certificate_global is defined %}
{%- for certificate_name, certificate in workspace.acm_certificate_global.items() %}
| global (us-east-1) | {{ certificate_name }} | {{ certificate.dns_validation_records|map(attribute='domain_name') |join(',') }} | {{ certificate.arn }}
{%- endfor %}
{%- endif %}
{%- endif %}
{%- endif %}
{%- endfor %}

{%- if not has_certificates.found %}

> **Note:** No ACM certificates have been deployed yet. Certificates will appear here after running `terragrunt apply` in network stacks with ACM configuration.

{%- endif %}