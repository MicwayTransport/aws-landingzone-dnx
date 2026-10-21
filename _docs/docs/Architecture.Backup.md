# Backup


DNX Foundation uses AWS Backup as the default mechanism of data protection across AWS services. It will help you support your regulatory compliance or business policies.

AWS Backup offers a cost-effective, fully managed, policy-based service that further simplifies data protection at scale for a few service in DNX Foundation such as Amazon Elastic Compute Cloud (Amazon EC2) instances, Amazon Elastic Block Store (Amazon EBS) volumes, Amazon Relational Database Service (Amazon RDS) databases, Amazon Aurora clusters, Amazon Elastic File System (Amazon EFS) file systems, and Amazon FSx for Windows File Server file systems.

AWS Backup encrypts your backup data at rest and in transit, providing a comprehensive encryption solution that secures your backup data. The keys used to encrypt your AWS Backup data are independent of the keys used to encrypt the resources that the backups are based on. Having separate encryption keys for your production and backup data provides an important layer of protection for your applications

AWS Backup also allows you to centralize your backups into one or more accounts. Use a cross-account backup if you want to securely copy your backups to one or more AWS accounts in your organization for operational or security reasons. If your original backup is inadvertently deleted, you can copy the backup from its destination account to its source account, and then start the restore. Before you can do this, you must have two accounts that belong to the same organization in the AWS Organizations service.

DNX Foundation enables customer to automate the backup policy creation by setting up schedule, lifecycle and encryption and etc into the terraform workspace.


