output "alb_dns_name" {
  description = "Open http://<this> in a browser to verify the deployment."
  value       = module.compute.alb_dns_name
}

output "vpc_id" {
  description = "ID of the dev VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the dev public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the dev private subnets."
  value       = module.vpc.private_subnet_ids
}

output "instance_id" {
  description = "ID of the dev EC2 instance."
  value       = module.compute.instance_id
}
