# EKS

EKS is a managed Kubernetes from AWS.

To understand more about EKS, please read: [https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html]().

![AWS EKS HLD](images/hld_aws_eks.png)

## Node Groups

The worker nodes are created using Node Groups and are managed by EKS.

You might have one or more Node Groups, usually multiple groups are used to isolate workloads or when workloads have different instance requirements.

As an example you might have one Node Group for normal applications and other to run long-running jobs that cannot run on Spot instances.

Or one for stateless apps and another for stateful services that to not autoscale.

Node Groups are deployed to the Private Subnet as they need internet access to download public docker images.

## Secrets

Kubernetes has its own Secrets [https://kubernetes.io/docs/concepts/configuration/secret/](), but there are controllers that integrate with AWS services like Secrets Manager and SSM Parameters.

The controller **External Secrets** can map external secrets from Secrets Manager and SSM to Kubernetes secrets.

A description on how to use the controller can be found at [https://github.com/DNXLabs/terraform-aws-eks-external-secrets]().

For more information on secrets, check the [Secrets](Architecture.Secrets.md) section of this document.

## Logs

When using the Cloudwatch Logs controller, logs are automatically sent to Cloudwatch Logs.

Always make sure that your apps send logs to the stdout when building the container image.

For more information, check the [Logs](Architecture.Logs.md) section of this document.

## How to Configure Controllers

EKS controllers are deployed using Helm charts enclosed by Terraform.

These controllers can be enabled and configured in the `kubernetes` stack of this foundation.

In the configuration file there will be a list of controllers that can be used, some might be enabled already.

## EKS Blueprints Add-ons

The platform stack includes integration with **AWS EKS Blueprints Add-ons**, which provides a systematic way to deploy and manage Kubernetes add-ons.

{%- set has_eks_addons = namespace(found=false) %}
{%- for workspace_name, workspace in outputs.platform.items() %}
{%- if not ('template' in workspace_name) and workspace.eks_addons_info is defined %}
{%- set has_eks_addons.found = true %}
{%- endif %}
{%- endfor %}

{%- if has_eks_addons.found %}

### Deployed Add-ons

{%- for workspace_name, workspace in outputs.platform.items() %}
{%- if not ('template' in workspace_name) and workspace.eks_addons_info is defined %}

**{{ workspace_name.replace('_', ' ').title() }}**

{%- if workspace.eks_addons_info.enabled_addons is defined and workspace.eks_addons_info.enabled_addons | length > 0 %}

Enabled add-ons:
{%- for addon in workspace.eks_addons_info.enabled_addons %}
- {{ addon }}
{%- endfor %}

{%- if workspace.eks_addons_argocd_url is defined %}
- **ArgoCD URL**: {{ workspace.eks_addons_argocd_url }}
{%- endif %}

{%- if workspace.eks_addons_grafana_url is defined %}
- **Grafana URL**: {{ workspace.eks_addons_grafana_url }}
{%- endif %}

{%- else %}
No add-ons enabled in this workspace.
{%- endif %}

{%- endif %}
{%- endfor %}

{%- else %}

> **Note:** EKS Blueprints add-ons have not been configured yet. Add-on information will appear here after enabling `eks_addons` in platform stack configuration.

{%- endif %}

### Available Add-ons

The EKS Blueprints integration supports:

- **EKS Native Add-ons**: vpc-cni, coredns, kube-proxy, aws-ebs-csi-driver, aws-efs-csi-driver
- **Observability**: metrics-server, aws-cloudwatch-metrics, aws-for-fluentbit
- **GitOps**: argocd, argocd-image-updater
- **Autoscaling**: cluster-autoscaler, karpenter
- **Ingress**: aws-load-balancer-controller, external-dns
- **Security**: external-secrets, secrets-store-csi-driver
- **Service Mesh**: aws-gateway-api-controller

For configuration details, see the [EKS Blueprints documentation](https://aws-ia.github.io/terraform-aws-eks-blueprints-addons/).