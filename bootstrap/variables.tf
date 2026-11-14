variable "region" {
  description = "AWS region for the state bucket and lock table."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for the bootstrap resource names."
  type        = string
  default     = "terraform-state"
}
