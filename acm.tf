# =================================================================================
# SSL/TLS CERTIFICATE (AWS ACM)
# =================================================================================
# This file provisions a free public SSL certificate from AWS Certificate Manager.
# It also automatically creates the necessary DNS records in Route 53 to prove
# that you own the domain.
#
# IMPORTANT: ACM certificates for CloudFront MUST be created in the us-east-1 region.
# =================================================================================

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "cert" {
  provider = aws.us_east_1

  domain_name       = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method = "DNS"

  tags = {
    Name = "Certificate for ${var.domain_name}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create the DNS validation records in our Route 53 hosted zone.
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.primary.zone_id
}

# This resource waits until the certificate has been successfully validated via DNS.
resource "aws_acm_certificate_validation" "cert" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}