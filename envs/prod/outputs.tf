# SKELETON ONLY — DO NOT APPLY.

output "alb_dns_name" {
  description = "Would be the prod load balancer DNS name, if prod were deployed."
  value       = module.compute.alb_dns_name
}

output "vpc_id" {
  description = "Would be the prod VPC ID, if prod were deployed."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Would be the prod public subnet IDs, if prod were deployed."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Would be the prod private subnet IDs, if prod were deployed."
  value       = module.vpc.private_subnet_ids
}

output "instance_id" {
  description = "Would be the prod EC2 instance ID, if prod were deployed."
  value       = module.compute.instance_id
}
