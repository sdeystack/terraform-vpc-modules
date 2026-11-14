# Bootstrap: creates the S3 bucket and DynamoDB table that hold Terraform
# remote state and locking for the envs/ projects.
#
# This setup intentionally uses LOCAL state. The bucket and table must exist
# before any project can use them as a backend, so they are built first,
# with their own state file on your laptop. That is the chicken-and-egg
# answer: bootstrap first, then point the real projects at what it built.
#
# Destroy order matters: destroy envs/dev FIRST, then this bootstrap setup.
# The bucket uses force_destroy (lab only) so `terraform destroy` here can
# empty it. Never use force_destroy on a production state bucket.

provider "aws" {
  region = var.region
}

resource "random_pet" "suffix" {
  length = 2
}

resource "aws_s3_bucket" "state" {
  bucket        = "${var.name_prefix}-${random_pet.suffix.id}"
  force_destroy = true # lab only: lets `terraform destroy` empty the bucket

  tags = {
    Name    = "${var.name_prefix}-${random_pet.suffix.id}"
    Purpose = "Terraform remote state lab"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "locks" {
  name         = "${var.name_prefix}-locks-${random_pet.suffix.id}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = "${var.name_prefix}-locks-${random_pet.suffix.id}"
    Purpose = "Terraform state locking lab"
  }
}
