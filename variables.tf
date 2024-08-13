variable "email_domain_zone_id" {
  type        = string
  description = "This is the hosted zone id for the email domain"
}

variable "dkim_signing_key_length" {
  type        = string
  description = "This is the bit lenght of the dkim SES will create with EasyDKIM: https://docs.aws.amazon.com/ses/latest/dg/send-email-authentication-dkim.html"
  default     = "RSA_2048_BIT"
  validation {
    condition     = contains(["RSA_1024_BIT", "RSA_2048_BIT"], var.dkim_signing_key_length)
    error_message = "dkim_singing_key_length only supports the values: 'RSA_1024_BIT' and 'RSA_2048_BIT'"
  }
}

variable "dmarc_policy" {
  type        = string
  description = "DMARC policy for email servies to apply if an email flowing throug failed DMARC verification: https://docs.aws.amazon.com/ses/latest/dg/send-email-authentication-dmarc.html#send-email-authentication-dmarc-implement"
  default     = "none"
  validation {
    condition     = contains(["none", "quarantine", "reject"], var.dmarc_policy)
    error_message = "dmarc policy must be one of 'none', 'quarantine' or 'reject'"
  }
}

variable "dmarc_rua" {
  type        = string
  description = "DMARC Reporting URI for Aggregare repoting. This is how email providers will send reports for failed dmarc checks. This is typically a mailto link reports will be sent to. For example: 'mailto:dmarc_report@domain.com'"
  default     = "mailto:dmarc_reports@domain.com"
  validation {
    condition     = startswith(var.dmarc_rua, "mailto:")
    error_message = "value needs to be a mailto link, so should start with 'mailto:'"
  }
}

variable "mail_from_subdomain" {
  type        = string
  description = "A sub domain off of the primary email domain that will be used for feedback"
  default     = "feedback"
}

variable "scan_incoming_email" {
  type        = bool
  description = "If true incoming email will be scanned by SES"
  default     = true
}

variable "enable_incoming_email" {
  type        = bool
  description = "If true then an MX record is created for receiving email on the pirmary domain and an SES event is created to store email in an S3 bucket"
  default     = false
}

variable "recipient_list" {
  type        = list(string)
  description = "A List of recipients to trigger the ses event rule. If null all emails to the configured mail domain will be picked up by the recipient rule action"
  nullable    = true
  default     = null
}

variable "existing_receipt_rule_set_name" {
  type        = string
  description = "If you have an existing receipt rule set the rule for the new domain will be attached to the existing, otherwise a new rule set will be created and activated"
  nullable    = true
  default     = null
}
