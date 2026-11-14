terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Partial backend configuration: the bucket, key, region, and lock table
  # come from backend.hcl at init time (`terraform init
  # -backend-config backend.hcl`). The bucket name is created by the
  # bootstrap step, so it cannot be written here in advance.
  backend "s3" {}
}
