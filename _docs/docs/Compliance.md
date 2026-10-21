# Compliance

The DNX Foundation AWS Well-Architected Foundation helps companies build a secure, high-performance, resilient, and efficient infrastructure for applications and workloads based on the AWS cloud.

Following the 5 pillars recommended by AWS: operational excellence, security, reliability, performance and cost optimisation, the Well-Architected foundation offers a consistent, scalable and flexible approach, enabling customisations relevant to each project and goals to be achieved.

The architecture is based on best-practice concepts and principles for designing and running workloads in the cloud.
The DNX Foundation AWS Well-Architected Foundation addresses several key requirements for certain security standards and compliance certifications, including PCI-DSS, HIPAA, GDPR and ASAE-3150 Security of CDR Data, converging to the AWS Well Architected Framework, to support the needs of each project.

Further information on how AWS infrastructure complies with CPS 234, please refer to:
https://d1.awsstatic.com/whitepapers/compliance/AWS_User_Guide_to_Financial_Services_Regulations_and_Guidelines_in_Australia.pdf

And for information regarding how AWS infrastructure complies with ISO-27001, please refer to:
https://aws.amazon.com/compliance/iso-27001-faqs/

Here are some of those requirements covered by the DNX Foundation Well Architected Foundation:

## Account Segregation
* One of the first security points is to isolate production workloads from development and testing workloads.
* Segregation is intended to provide a strong logical boundary between workloads that process data of different sensitivity levels, as defined by external compliance requirements (such as PCI-DSS, HIPAA or CDR), and workloads that do not.
* DNX Foundation Well Architected Foundation was designed following the principle of account segregation widely recommended by AWS and other security and compliance institutions.
* The production environment has a dedicated AWS account for this purpose.

## Role-Based Access
* Role-based access is implemented to limit user access rights to only that necessary for personnel to perform their assigned responsibilities. Role-based access is assigned in accordance with the principles of the least necessary privileges and segregation of duties.
* User access to the environment is restricted to authorized users managed by the SSO. Each user is assigned specific AWS IAM roles compatible with the role to be performed following the concept of the least privilege.
* This item can help you with the following compliance standards: AWS Well-Architected Framework.

## Unique IDs
* All users with access to the environment will have a unique username and password (MFA is recommended). User management will be done through Identity Provider/SSO. 
* The Root user (default in all accounts created on AWS) has no access keys, ensuring that the user only has console access. Console access using the Root user is MFA protected using a software security token.
* This item can help you with the following compliance standards: AWS Well-Architected Framework, PCI-DSS and ASAE-3150 Security of CDR Data.

## Multi-Factor Authentication
* Multi-Factor Authentication (MFA) is enabled for root account in order to secure the AWS environment and adhere to security best practices.
* DNX suggests that all users have MFA enforced through identity provider / SSO.
* This item can help you with the following compliance standards: AWS Well-Architected Framework, GDPR, PCI-DSS and ASAE-3150 Security of CDR Data.

## Encryption
* A robust network of security controls to help protect data, including encrypting data in transit using CMK's and Certificates Managed by AWS Certifications Manager.
* With encryption enabled, your EBS volumes can contain very sensitive and critical data. EBS encryption and decryption are handled transparently using a CMK previously intended for this purpose, requiring no further action by the server instance or application.
* This item can help you with the following compliance standards: AWS Well-Architected Framework, GDPR, PCI-DSS, HIPAA and ASAE-3150 Security of CDR Data.

## Alarms
* The DNX Well Architected Foundation implements a set of CloudWatch/CloudTrail based security alarms monitoring the AWS environment. These alarms are triggered whenever a critical configuration change is made. Some examples of these alarms, but not limited to: Root account login, Route tables changes, Network Access Control List changes, and IAM policies changes.
* This rule can help you with the following compliance standards: AWS Well-Architected Framework, PCI-DSS and ASAE-3150 Security of CDR Data.