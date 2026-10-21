# Kubernetes

The kubernetes terraform stack is responsible for deploying all the resources that are required to run your workloads.

This stack requires the following stacks:

* Audit
* Baseline
* Identity
* Platform

This stack applies to AWS accounts of the **workload** type.

## Terraform Workspaces

One terraform workspace should be used per EKS Cluster deployed by the Platform stack in the account.