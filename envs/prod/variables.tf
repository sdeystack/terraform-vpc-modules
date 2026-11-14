# SKELETON ONLY — DO NOT APPLY. See versions.tf for why this folder exists.

variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name, used in resource names and tags."
  type        = string
  default     = "prod"
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "vpc-lab-prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the prod VPC. Different from dev on purpose."
  type        = string
  default     = "10.1.0.0/16"
}

variable "azs" {
  description = "Availability zones for the prod subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "EC2 instance type for prod."
  type        = string
  default     = "t3.micro"
}

variable "allowed_http_cidrs" {
  description = "CIDR blocks allowed to reach the ALB on port 80 (lab only)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
