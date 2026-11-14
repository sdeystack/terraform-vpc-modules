output "state_bucket" {
  description = "Name of the S3 bucket holding remote state. Copy into backend.hcl."
  value       = aws_s3_bucket.state.id
}

output "lock_table" {
  description = "Name of the DynamoDB table used for state locking. Copy into backend.hcl."
  value       = aws_dynamodb_table.locks.name
}

output "region" {
  description = "Region of the bootstrap resources."
  value       = var.region
}
