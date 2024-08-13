output "email_identity_arn" {
  description = "The arn of the email identity"
  value       = aws_sesv2_email_identity.this.arn
}

output "email_identity_id" {
  description = "The id of the email identity"
  value       = aws_sesv2_email_identity.this.id
}

output "receipt_rule_set_name" {
  description = "The name of the receipt rule set"
  value       = local.rule_set_name
}

output "email_s3_bucket_arn" {
  description = "The arn of the S3 bucket where incoming emails will be stored"
  value       = try(aws_s3_bucket.this[0].arn, null)
}

output "email_s3_bucket" {
  description = "The name of the S3 bucket where incoming emails will be stored"
  value       = try(aws_s3_bucket.this[0].bucket, null)
}
