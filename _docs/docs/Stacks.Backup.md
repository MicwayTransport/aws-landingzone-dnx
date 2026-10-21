# Backup

The platform terraform stack is responsible for deploying all the resources that are required to run your workloads.

This stack requires the following stacks:

* Baseline
* Identity

This stack applies to AWS accounts of the **workload** and **backup** types.

![A typical AWS Backup stack structure HLD](images/hld_aws_backup_overview.png)

## Features

### Backups

Enables AWS Backups that automatically backs up resources tagged properly.

![A typical AWS Backup structure HLD](images/hld_aws_backup.jpg)

### Cross-account backups

Opt-in for automatic cross-account backup copies and On-demand cross-account backup restore.

Use a cross-account backup if you want to securely copy your backups to one or more AWS accounts in your organization for operational or security reasons. If your original backup is inadvertently deleted, you can copy the backup from its destination account to its source account, and then start the restore.

You may choose to have a single centralized backup vault in your Backup Center Account or even to have vaults per workspaces, environments, etc. 

![AWS Backup cross-account options structure HLD](images/hld_aws_backup_cross_account.jpg)

