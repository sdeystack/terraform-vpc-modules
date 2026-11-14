variable "name_prefix" {
  description = "Prefix for resource names, e.g. vpc-lab-dev."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to place the load balancer and instance in."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the load balancer."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the instance. The instance uses the first one."
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type. t3.micro is free-tier eligible on new accounts."
  type        = string
  default     = "t3.micro"
}

variable "allowed_http_cidrs" {
  description = "CIDR blocks allowed to reach the load balancer on port 80. Open to the world for this short-lived lab; restrict in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Extra tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
