{% set audit_account = stacks.identity.workspaces.values() | selectattr('account_name', 'equalto', 'audit') | first %}
# Billing

Billing IAM roles and budgets are configured by a CloudFormation template deployed to the Master (aka Management) account.

It's a limitation that all things related to billing and cost need to be managed from the Master account as it's where the centralised billing of your AWS Organization happens.

The CloudFormation template lives at: `_cf-templates/optional/master/billing.cf.yml`

This template can deploy the following resources:

## DNX Access to Billing

Controlled by the parameter `DNX` in the template, when `true`, it will create an IAM role called `{{org_name}}DNXBillingAccess` with a policy that allows DNX to view the Organization billing, cost explorer, budgets and cost usage reports.

## Billing role

The template creates an IAM role called `BillingAccess` that trusts your SSO via an Identity Provider set when deploying it.

To use the `BillingAccess` role, set this role in your IDP:

```
arn:aws:iam::{{audit_account.aws_account_id}}:role/BillingAccess,arn:aws:iam::{{audit_account.aws_account_id}}:saml-provider/{{org_name}}-sso
```

## Budget

If the option `BudgetEnabled` is set to true, a Budget alarm is created for the amount specified in the `BudgetAmount` parameter (in USD).

The budget created is monthly forecasted, which means if AWS detects in the beginning of the month that the billing for the end of the month will exceed the value, you get an email alert, allowing you to prevent it from happening.

## Anomaly Detection

The option `CostAnomaly`, when set to true will work similarly to Budget but with a dynamic value, calculated based on your previous billings. When the value is above the threshold set, it will generate an alarm.

The detection is done by service, which means it will detect abuse on individual services instead of the whole organization billing. The check is done daily.

More info at https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/getting-started-ad.html
