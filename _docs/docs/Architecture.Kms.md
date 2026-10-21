# KMS keys  

## Customer managed keys

The KMS keys that you create are customer managed keys. Customer managed keys are KMS keys in your AWS account that you create, own, and manage. You have full control over these KMS keys, including establishing and maintaining their key policies, IAM policies, and grants, enabling and disabling them, rotating their cryptographic material, adding tags, creating aliases that refer to the KMS keys, and scheduling the KMS keys for deletion. The customer managed key provides more granular control than an AWS managed Key.

DNX Foundation is able to use different customer-managed keys per service when it is enabled instead of using the default AWS managed key. e.g. SSM parameters, ECR repository, AWS Backup, EFS, EBS, and RDS.

## AWS managed keys

AWS managed keys are KMS keys in your account created, managed, and used on your behalf by an AWS service integrated with AWS KMS. Some AWS services support only an AWS managed key. Others use an AWS owned key or offer you a choice of KMS keys.

You can view the AWS managed keys in your account, view their key policies, and audit their use in AWS CloudTrail logs. However, you cannot manage these KMS keys, rotate them, or change their key policies. And, you cannot use AWS managed keys in cryptographic operations directly; the service that creates them uses them on your behalf. You cannot change the rotation schedule.

## Comparison

The following chart summarizes the key differences and similarities between AWS-managed Key and customer-managed Key.

|    | AWS-managed Key   |   Customer-managed Key        |
| ---------------| ------------- | ------------- |
| Creation         | AWS generated on customer’s behalf | Customer generated |
| Rotation          | Once every three years automatically | Once a year automatically through opt-in or on-demand manually| 
| Deletion| Can’t be deleted | Can be deleted | 
| Scope of use      | Limited to a specific AWS service.| Controlled via KMS/IAM policy|
| Key Access Policy| AWS managed | Customer managed|
| User Access Management | IAM policy | IAM policy |