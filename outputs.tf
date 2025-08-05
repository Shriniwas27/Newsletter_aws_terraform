# =================================================================================
# OUTPUTS
# =================================================================================
# This file defines the outputs of our Terraform configuration.
# =================================================================================

output "application_access_point" {
  description = "The main access point for the application. This will be the custom domain if created, otherwise it will be the ALB's DNS name."
  value       = var.create_dns_and_cdn ? "https://www.${var.domain_name}" : "http://${aws_lb.main.dns_name}"
}

output "alb_dns_name" {
  description = "The direct DNS name of the Application Load Balancer."
  value       = aws_lb.main.dns_name
}

output "primary_db_endpoint" {
  description = "The endpoint of the primary (writer) RDS database instance."
  value       = aws_db_instance.primary.endpoint
  sensitive   = true
}

output "replica_db_endpoint" {
  description = "The endpoint of the replica (reader) RDS database instance."
  value       = aws_db_instance.replica.endpoint
  sensitive   = true
}

output "route53_nameservers" {
  description = "If you created a domain, update these nameservers at your domain registrar."
  
  value       = var.create_dns_and_cdn ? aws_route53_zone.primary[0].name_servers : ["Not created because create_dns_and_cdn is false."]
}
