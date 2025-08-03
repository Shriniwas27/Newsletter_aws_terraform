# =================================================================================
# OUTPUTS
# =================================================================================
# This file defines the outputs of our Terraform configuration. After `terraform apply`
# runs, it will print the values of these outputs to the console. This is useful
# for getting important information like the public URL of our application.
# =================================================================================

output "application_url" {
  description = "The final public URL of the application."
  value       = "https://www.${var.domain_name}"
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution."
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer (for direct access)."
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
  description = "CRITICAL: Update these nameservers at your domain registrar."
  value       = aws_route53_zone.primary.name_servers
}