# AWS SES Application Email Module

This module creates an SES email setup for use with AWS IAM Role Access. You can create an IAM User with access and leverage that to send email via direct access to SMTP, but if possible its best to avoid that and leverage the AWS CLI.

This module configures DKIM, SPF and DMARC for a domain (not a specific email address) based on a Route 53 Hosted Zone ID. This means that you must have your email domain as a Route53 Hosted Zone.

This module can be configured to allow incoming email. The recipt rule set can be used to configure how incoming emails are handled.

AWS SES starts in a sandbox mode that puts limitation on how and who you can send email to. To remove these limits you must request production SES access. Please see https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html for details.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.42.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.62.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_route53_record.dkim](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.dmarc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.mx_receive](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.mx_send_mail_from](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.spf_mail_from](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_ses_active_receipt_rule_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_active_receipt_rule_set) | resource |
| [aws_ses_receipt_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_receipt_rule) | resource |
| [aws_ses_receipt_rule_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_receipt_rule_set) | resource |
| [aws_sesv2_configuration_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_configuration_set) | resource |
| [aws_sesv2_email_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_email_identity) | resource |
| [aws_sesv2_email_identity_mail_from_attributes.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sesv2_email_identity_mail_from_attributes) | resource |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dkim_signing_key_length"></a> [dkim\_signing\_key\_length](#input\_dkim\_signing\_key\_length) | This is the bit lenght of the dkim SES will create with EasyDKIM: https://docs.aws.amazon.com/ses/latest/dg/send-email-authentication-dkim.html | `string` | `"RSA_2048_BIT"` | no |
| <a name="input_dmarc_policy"></a> [dmarc\_policy](#input\_dmarc\_policy) | DMARC policy for email servies to apply if an email flowing throug failed DMARC verification: https://docs.aws.amazon.com/ses/latest/dg/send-email-authentication-dmarc.html#send-email-authentication-dmarc-implement | `string` | `"none"` | no |
| <a name="input_dmarc_rua"></a> [dmarc\_rua](#input\_dmarc\_rua) | DMARC Reporting URI for Aggregare repoting. This is how email providers will send reports for failed dmarc checks. This is typically a mailto link reports will be sent to. For example: 'mailto:dmarc_report@domain.com' | `string` | `"mailto:dmarc_reports@domain.com"` | no |
| <a name="input_email_domain_zone_id"></a> [email\_domain\_zone\_id](#input\_email\_domain\_zone\_id) | This is the hosted zone id for the email domain | `string` | n/a | yes |
| <a name="input_enable_incoming_email"></a> [enable\_incoming\_email](#input\_enable\_incoming\_email) | If true then an MX record is created for receiving email on the pirmary domain and an SES event is created to store email in an S3 bucket | `bool` | `false` | no |
| <a name="input_existing_receipt_rule_set_name"></a> [existing\_receipt\_rule\_set\_name](#input\_existing\_receipt\_rule\_set\_name) | If you have an existing receipt rule set the rule for the new domain will be attached to the existing, otherwise a new rule set will be created and activated | `string` | `null` | no |
| <a name="input_mail_from_subdomain"></a> [mail\_from\_subdomain](#input\_mail\_from\_subdomain) | A sub domain off of the primary email domain that will be used for feedback | `string` | `"feedback"` | no |
| <a name="input_recipient_list"></a> [recipient\_list](#input\_recipient\_list) | A List of recipients to trigger the ses event rule. If null all emails to the configured mail domain will be picked up by the recipient rule action | `list(string)` | `null` | no |
| <a name="input_scan_incoming_email"></a> [scan\_incoming\_email](#input\_scan\_incoming\_email) | If true incoming email will be scanned by SES | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_email_identity_arn"></a> [email\_identity\_arn](#output\_email\_identity\_arn) | The arn of the email identity |
| <a name="output_email_identity_id"></a> [email\_identity\_id](#output\_email\_identity\_id) | The id of the email identity |
| <a name="output_email_s3_bucket"></a> [email\_s3\_bucket](#output\_email\_s3\_bucket) | The name of the S3 bucket where incoming emails will be stored |
| <a name="output_email_s3_bucket_arn"></a> [email\_s3\_bucket\_arn](#output\_email\_s3\_bucket\_arn) | The arn of the S3 bucket where incoming emails will be stored |
| <a name="output_receipt_rule_set_name"></a> [receipt\_rule\_set\_name](#output\_receipt\_rule\_set\_name) | The name of the receipt rule set |
