# This is a sample aws cli command to test sending an email if your email domain was example.com
#
# aws ses send-email --from test_sender@exmaple.com --to user@exmaple.com --text "This is a test message" --subject "This is the subject"

data "aws_route53_zone" "this" {
  name         = var.email_domain
  private_zone = false
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

# site deployer IAM
resource "aws_iam_role" "email_sender" {
  name_prefix        = "${var.email_domain}-email_sender-role-"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "email_sender" {
  statement {
    sid    = "AllowSendEmail"
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]
    resources = [
      "*"
    ]
    condition {
      test = "StringEquals"
      values = [
        "test_sender@${var.email_domain}"
      ]
      variable = "ses:FromAddress"
    }
  }
}

resource "aws_iam_policy" "email_sender" {
  name_prefix = "${var.email_domain}-email-sender-"
  policy      = data.aws_iam_policy_document.email_sender.json
}

resource "aws_iam_role_policy_attachment" "email_sender" {
  role       = aws_iam_role.email_sender.name
  policy_arn = aws_iam_policy.email_sender.arn
}

module "example" {
  source = "../"

  email_domain_zone_id  = data.aws_route53_zone.this.zone_id
  enable_incoming_email = true
}
