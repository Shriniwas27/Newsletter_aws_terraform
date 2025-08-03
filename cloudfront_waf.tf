# =================================================================================
# CDN (CLOUDFRONT) & FIREWALL (WAF)
# =================================================================================
# This file creates a Web Application Firewall (WAF) with common security rules
# and then sets up a CloudFront distribution to act as a CDN. The distribution
# is configured to use the WAF, the ACM certificate, and to forward traffic
# to your Application Load Balancer.
# =================================================================================

# --- AWS WAF v2 ---

# Create a Web ACL (Access Control List)
resource "aws_wafv2_web_acl" "main" {
  name  = "fastapi-waf-acl"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Rule 1: Common SQL Injection Protection
  rule {
    name     = "SQLi"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLi"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: Common Rule Set (includes XSS, etc.)
  rule {
    name     = "CommonRuleSet"
    priority = 2

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "fastapi-waf"
    sampled_requests_enabled   = true
  }
}

# --- AWS CloudFront ---

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "ALB-${aws_lb.main.name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront for FastAPI App"
  default_root_object = "index.html"

  aliases = ["www.${var.domain_name}"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALB-${aws_lb.main.name}"

    forwarded_values {
      query_string = true
      headers      = ["Origin"]
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100" # Use only North America and Europe edge locations for cost savings

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method  = "sni-only"
  }

  web_acl_id = aws_wafv2_web_acl.main.arn
}
