output "alb_dns_name" {
  description = "DNS name of the load balancer. Open http://<this> in a browser to verify."
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ARN of the load balancer."
  value       = aws_lb.this.arn
}

output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.web.id
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance (no public IP by design)."
  value       = aws_instance.web.private_ip
}
