variable "email_domain" {
  type        = string
  description = "This is the domain from which you want to use for email"
}

variable "enable_incomming_email" {
  type        = bool
  description = "If true this will enable receiving email which will be sent to an S3 bucket."
  default     = true
}
