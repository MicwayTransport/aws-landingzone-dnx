# Transit Gateway

![AWS Transit Gateway HLD](images/hld_aws_transit_gateway.png)

## Overview

AWS Transit Gateway acts as a cloud router to connect VPCs and on-premises networks through a central hub. This simplifies network architecture and reduces the operational overhead of managing multiple point-to-point connections.

In the DNX Foundation architecture, Transit Gateway is deployed in the **Network Hub** account and provides connectivity between:

- Workload account VPCs (spoke accounts)
- Shared Services VPCs
- On-premises networks (via VPN or Direct Connect)

## Transit Gateway Configuration

{%- set tgw_hubs = [] %}
{%- for workspace_name, workspace in outputs.network.items() %}
{%- if not ('template' in workspace_name) and workspace.transit_gateway is defined and workspace.transit_gateway.transit_gateway_id is defined %}
{%- set _ = tgw_hubs.append((workspace_name, workspace)) %}
{%- endif %}
{%- endfor %}

{%- if tgw_hubs | length > 0 %}

### Transit Gateway Details

| Account | Transit Gateway ID | ARN | CIDR Blocks | Owner Account |
| ------- | ------------------ | --- | ----------- | ------------- |
{%- for workspace_name, workspace in tgw_hubs %}
| {{ stacks.network.workspaces[workspace_name].account_name }} | {{ workspace.transit_gateway.transit_gateway_id }} | {{ workspace.transit_gateway.transit_gateway_arn }} | {{ workspace.transit_gateway.transit_gateway_cidr_blocks | join(', ') }} | {{ workspace.transit_gateway.transit_gateway_account_owner_id }} |
{%- endfor %}

### Route Tables

Transit Gateway uses route tables to control traffic flow between attached VPCs. Each route table can have different routing policies.

{%- for workspace_name, workspace in tgw_hubs %}

#### {{ stacks.network.workspaces[workspace_name].account_name }} Route Tables

| Route Table Name | Route Table ID | Purpose |
| ---------------- | -------------- | ------- |
{%- for rt_name, rt_id in workspace.transit_gateway.transit_gateway_route_table_ids.items() %}
{%- if rt_id %}
| {{ rt_name }} | {{ rt_id }} | {{ rt_name | replace('-', ' ') | title }} |
{%- endif %}
{%- endfor %}

{%- endfor %}

{%- else %}

> **Note:** No Transit Gateway has been deployed yet. Transit Gateway will be created in the Network Hub account to enable hub-and-spoke connectivity.

{%- endif %}

## Hub-and-Spoke Architecture

The Transit Gateway implements a hub-and-spoke network topology:

### Hub Account (Network Hub)
- Hosts the Transit Gateway
- Manages centralized routing
- Controls traffic inspection and egress
- Provides shared services connectivity

### Spoke Accounts (Workload Accounts)
- Attach their VPCs to the Transit Gateway
- Route inter-VPC traffic through the hub
- Isolated from each other by default
- Selective connectivity via route table associations