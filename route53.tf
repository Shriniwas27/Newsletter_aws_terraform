# =================================================================================
# DNS (ROUTE 53) - OPTIONAL
# =================================================================================
# These resources will only be created if var.create_dns_and_cdn is set to true.
# =================================================================================

resource "aws_route53_zone" "primary" {

  count = var.create_dns_and_cdn ? 1 : 0

  name = var.domain_name

  tags = {
    Name = "Hosted Zone for ${var.domain_name}"
  }
}

resource "aws_route53_record" "www" {

  count = var.create_dns_and_cdn ? 1 : 0

  zone_id = aws_route53_zone.primary[0].zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
   
    name                   = aws_cloudfront_distribution.s3_distribution[0].domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution[0].hosted_zone_id
    evaluate_target_health = false
  }
}
