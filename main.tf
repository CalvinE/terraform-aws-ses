/*
 * # AWS SES Application Email Module
 *
 * This module creates an SES email setup for use with AWS IAM Role Access. You can create an IAM User with access and leverage that to send email via direct access to SMTP, but if possible its best to avoid that and leverage the AWS CLI.
 *
 * This module configures DKIM, SPF and DMARC for a domain (not a specific email address) based on a Route 53 Hosted Zone ID. This means that you must have your email domain as a Route53 Hosted Zone.
 *
 * This module can be configured to allow incoming email. The recipt rule set can be used to configure how incoming emails are handled.
 *
 * AWS SES starts in a sandbox mode that puts limitation on how and who you can send email to. To remove these limits you must request production SES access. Please see https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html for details.
 */
data "aws_route53_zone" "this" {
  zone_id      = var.email_domain_zone_id
  private_zone = false
}

resource "aws_sesv2_configuration_set" "this" {
  configuration_set_name = "primary"

  delivery_options {
    tls_policy = "REQUIRE"
  }

  reputation_options {
    reputation_metrics_enabled = true
  }

  sending_options {
    sending_enabled = true
  }
}

resource "aws_sesv2_email_identity" "this" {
  email_identity = data.aws_route53_zone.this.name

  dkim_signing_attributes {
    next_signing_key_length = var.dkim_signing_key_length
  }

  configuration_set_name = aws_sesv2_configuration_set.this.configuration_set_name
}

# DKIM - NOTE: https://docs.aws.amazon.com/ses/latest/dg/send-email-authentication-dkim-easy-managing.html
resource "aws_route53_record" "dkim" {
  count = 3

  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${aws_sesv2_email_identity.this.dkim_signing_attributes[0].tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${aws_sesv2_email_identity.this.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]
}

# SPF - NOTE: https://docs.aws.amazon.com/ses/latest/dg/send-email-authentication-spf.html

# NOTE: A mail from address is needed to enable spf
# https://docs.aws.amazon.com/ses/latest/dg/mail-from.html
resource "aws_sesv2_email_identity_mail_from_attributes" "this" {
  email_identity   = aws_sesv2_email_identity.this.email_identity
  mail_from_domain = "${var.mail_from_subdomain}.${data.aws_route53_zone.this.name}"
}

data "aws_region" "this" {}

resource "aws_route53_record" "mx_send_mail_from" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = aws_sesv2_email_identity_mail_from_attributes.this.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${data.aws_region.this.name}.amazonses.com"]
}

resource "aws_route53_record" "spf_mail_from" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = aws_sesv2_email_identity_mail_from_attributes.this.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

# DMARC - NOTE: https://docs.aws.amazon.com/ses/latest/dg/send-email-authentication-dmarc.html
resource "aws_route53_record" "dmarc" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "_dmarc"
  type    = "TXT"
  ttl     = "600"
  records = ["v=DMARC1;p=${var.dmarc_policy};rua=${var.dmarc_rua}"]
}


# Email Receiving Code
locals {
  bucket_name = "email-${replace(data.aws_route53_zone.this.name, ".", "-")}"
}

resource "aws_route53_record" "mx_receive" {
  count = var.enable_incoming_email ? 1 : 0

  zone_id = data.aws_route53_zone.this.zone_id
  name    = data.aws_route53_zone.this.name
  type    = "MX"
  ttl     = "600"
  records = ["10 inbound-smtp.${data.aws_region.this.name}.amazonaws.com"]
}

resource "aws_s3_bucket" "this" {
  count = var.enable_incoming_email ? 1 : 0

  bucket = local.bucket_name
}

locals {
  new_rule_set_name = "default_rule_set"
  receipt_rule_name = "receive-${data.aws_route53_zone.this.name}"
}

resource "aws_ses_receipt_rule_set" "this" {
  count = (var.enable_incoming_email && var.existing_receipt_rule_set_name == null) ? 1 : 0

  rule_set_name = local.new_rule_set_name

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  rule_set_name = try(aws_ses_receipt_rule_set.this[0].rule_set_name, var.existing_receipt_rule_set_name)
}

resource "aws_ses_receipt_rule" "this" {
  count = var.enable_incoming_email ? 1 : 0

  name          = local.receipt_rule_name
  rule_set_name = local.rule_set_name
  recipients    = var.recipient_list
  enabled       = true
  scan_enabled  = var.scan_incoming_email
  # TODO: there are several actions that can happen here. Make this configurable...
  s3_action {
    position = 1

    bucket_name       = aws_s3_bucket.this[0].bucket
    object_key_prefix = "emails"
  }

  depends_on = [aws_s3_bucket_policy.this[0]]
}

resource "aws_ses_active_receipt_rule_set" "this" {
  # NOTE: If we are making a new rule set we will activate it. if you have an existing rule set you will need to activate it yourself.
  count = (var.enable_incoming_email && var.existing_receipt_rule_set_name == null) ? 1 : 0

  rule_set_name = local.rule_set_name

  lifecycle {
    create_before_destroy = true
  }
}

# NOTE: https://docs.aws.amazon.com/ses/latest/dg/receiving-email-permissions.html

data "aws_caller_identity" "this" {}

data "aws_iam_policy_document" "this" {
  count = var.enable_incoming_email ? 1 : 0

  statement {
    sid    = "AllowSESS3Write"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.this[0].arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.this.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:ses:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:receipt-rule-set/${local.rule_set_name}:receipt-rule/${local.receipt_rule_name}"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  count = var.enable_incoming_email ? 1 : 0

  bucket = aws_s3_bucket.this[0].bucket
  policy = data.aws_iam_policy_document.this[0].json
}
