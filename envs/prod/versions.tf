# SKELETON ONLY — DO NOT APPLY IN THIS SESSION.
#
# This folder shows what a second environment looks like: the SAME modules,
# different variables (different CIDR, different name prefix). Nothing here
# is deployed in this lab. Deploying prod would need its own backend key
# (prod/terraform.tfstate) and its own backend.hcl, on purpose not provided,
# plus a separate review. The point of this folder is the pattern, not a
# second deployment.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Same partial backend pattern as dev. A real prod deploy would pass its
  # own backend.hcl with key = "prod/terraform.tfstate".
  backend "s3" {}
}
