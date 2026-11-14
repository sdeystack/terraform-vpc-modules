variable "name_prefix" {
  description = "Prefix for resource names, e.g. vpc-lab-dev."
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "One CIDR per AZ for the public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "One CIDR per AZ for the private subnets."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_nat" {
  description = "Create a NAT gateway so private subnets can reach the internet for updates."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
