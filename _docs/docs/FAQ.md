# FAQ

- [Server Names and IP Addresses?](#how-server-names-and-ip-addresses-are-established%3F)
- [Firewall configurations?](#firewall-configurations%3F)
- [About Docker containers IP](#about-docker-containers-ip-(internet-protocol)-addresses)
- [Subnets across AZ](#subnets-across-availability-zones)
- [What are the benefits of running multiple containers?](#what-are-the-benefits-of-running-multiple-containers)
- [What is Elastic IP](#what-is-an-elastic-ip%3F)
- [Logging my ECS cluster](#logging-my-ecs-cluster)
- [How to set up a new GitLab pipeline?](#how-to-set-up-a-new-gitlab-pipeline%3F)
- [How to set up a new Bitbucket pipeline?](#how-to-set-up-a-new-bitbucket-pipeline%3F)
- [How to set up a new Github pipeline?](#how-to-set-up-a-github-pipeline%3F)
- [How to manage my credentials ](#how-to-manage-my-credentials%3F)
- [How to get billing insights?](#how-to-get-billing-insights%3F)
- [How to set up alarms?](#how-to-set-up-alarms%3F)
- [How to add a new user?](#how-to-add-a-new-user%3F)
- [Are operating system patches updated automatically?](#are-operating-system-patches-updated-automatically%3F)
- [Are physical access controls in place AWS datacenters?](#are-physical-access-controls-in-place-aws-datacenters%3F)


## How server names and IP Addresses are established?

There are no specific names for servers in your AWS cloud, as it runs on a Docker ECS (Elastic Container Service) Cluster structure. The servers are created and destroyed automatically according to the workloads and the Load Balancer.

The server names are usually: ecs-node-<cluster_name>. Regarding with IP addresses, there are no Elastic IPs or public IPs attached to it.

## Firewall configurations?

There are no firewalls to be configured. The traffic segregation and security are done through Security Groups and Network Access Control Lists (NACLs). Refer to AWS official documentation for NACLs (Network Access Control Lists) and Security Groups: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html - https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html.

## About Docker Containers IP (Internet Protocol) addresses

The default network is called bridge network, the Docker containers get an IP (Internet Protocol) from the host machine, which is internal to that machine.
New bridges are created for each docker compose.

## What are the benefits of running multiple containers

Running multiples containers you can have rapid resource scaling achieving high scalability in your AWS cloud, as each container takes seconds to provision.

## Subnets across Availability Zones

By default, subnets can talk between each other and each subnet lives in one AZ (Availability Zone).

## What is an Elastic IP?

An Elastic IP address is a static IPv4 address designed for dynamic cloud computing. An Elastic IP address is associated with your AWS account. With an Elastic IP address, you can mask the failure of an instance or software by rapidly remapping the address to another instance in your account. It is basically a public IPv4 address, which is reachable from the internet. It can be attached to your Elastic Load Balancer and publish to the internet.

More details here: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html.

## Logging my ECS cluster

The logs are centralized using CloudWatch, you can check metrics such as CPU Utilization, Memory Utilization and GPU Reservation. Check AWS documentation for more details: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cloudwatch-metrics.html.

## How to set up a new GitLab pipeline?

GitLab uses `.gitlab-ci.yml` file to set your pipeline up, this file is located in the root folder of your repository. Pipelines can be complex structures, it consists of jobs and stages used to achieve continuous integration, delivery and deployment

More details: https://docs.gitlab.com/ee/ci/yaml/README.html#configuration-parameters

## How to set up a new Bitbucket pipeline?

Bitbucket uses "bitbucket-pipelines.yml" file to set your pipeline up, this file is located in the root folder of your repository. Pipelines can be complex structures, it consists of jobs and stages used to achieve continuous integration, delivery and deployment.

More details: https://support.atlassian.com/bitbucket-cloud/docs/configure-bitbucket-pipelinesyml.

## How to set up a new github pipeline?

Github uses two .yml files. The files are github-ci-apply.yml and github-ci-plan.yml. Those files are used to set your pipeline up, this file is located in the folder .github/workflows of your repository. Pipelines can be complex structures, it consists of jobs and stages used to achieve continuous integration, delivery and deployment

More details: https://docs.github.com/en/free-pro-team@latest/actions

## How to manage my credentials?

You no longer have to manage credentials in your AWS accounts as we use SSO (Single Sign On) to authenticate in your cloud environment.

## How to get billing insights?

Use Trusted Advisor for billing insights, you have also security, performance, fault tolerance and service limits metrics.

Reference: https://aws.amazon.com/premiumsupport/technology/trusted-advisor/.

## How to set up alarms?

Use Cloud Watch to set up your alarms, you have 3 alarms created by your Auto Scaling Group for each ECS (Elastic Container Service) Cluster and CloudFront, they are:

Alarm Low - Memory Reservation
Alarm High - CPU Utilization
CloudFront - 500 errors

## How to add a new user?

Your AWS does not have IAM (Identity and Access Management) users created in your Production and Non-Production accounts, you can simply add and manage your users using your identity source.

More details: https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html.

## Are operating system patches updated automatically?

Your AWS platform uses Amazon Linux AMI (Amazon Machine Image) and updates are provided via a pre-configured yum repository hosted in each Amazon EC2 (Elastic Compute Cloud) region. You can find more details here:

https://aws.amazon.com/amazon-linux-ami/faqs.

## Are physical access controls in place AWS datacenters?

Yes, AWS has strict and secure protocols for controlling physical access to any datacenter. You can find more details consulting this AWS compliance section: https://aws.amazon.com/compliance/data-center/controls/
