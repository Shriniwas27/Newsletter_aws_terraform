# =================================================================================
# DNS (ROUTE 53)
# =================================================================================
# This file creates a public hosted zone in Route 53 for your custom domain.
# After this is created, you must manually update the nameservers at your
# domain registrar to the ones provided in the Terraform output.
# =================================================================================

resource "aws_route53_zone" "primary" {
  name = var.domain_name

  tags = {
    Name = "Hosted Zone for ${var.domain_name}"
  }
}

# This record will point your domain (e.g., www.your-app.com) to the CloudFront distribution.
# We use an alias record for better performance and to handle IP address changes automatically.
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
