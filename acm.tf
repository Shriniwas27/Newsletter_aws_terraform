# =================================================================================
# SSL/TLS CERTIFICATE (AWS ACM) - OPTIONAL
# =================================================================================
# These resources will only be created if var.create_dns_and_cdn is set to true.
# =================================================================================

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "cert" {

  count = var.create_dns_and_cdn ? 1 : 0

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

resource "aws_route53_record" "cert_validation" {

  for_each = {
    for dvo in var.create_dns_and_cdn ? aws_acm_certificate.cert[0].domain_validation_options : [] : dvo.domain_name => {
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
  zone_id         = aws_route53_zone.primary[0].zone_id
}


resource "aws_acm_certificate_validation" "cert" {
  count = var.create_dns_and_cdn ? 1 : 0

  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
