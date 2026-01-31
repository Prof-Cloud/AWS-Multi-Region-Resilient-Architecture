#Requesting SSL certificate
#cert on available in us-east-01
resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"


  tags = {
    Name = "SSL Cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#Validate cert before attaching to HTTPS listener
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]

  # Ensure CNAMEs exist first
  depends_on = [aws_route53_record.cert_validation]


}

#ACM certificate for London 
resource "aws_acm_certificate" "cert_2nd" {
  provider          = aws.London
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Name = "SSL certificate London"
  }
}


#Validate cert before attaching to HTTPS listener
resource "aws_route53_record" "cert_validation_2nd" {
  for_each = {
    for dvo in aws_acm_certificate.cert_2nd.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.hosted_zone.zone_id
}

#Validate cert before attaching to HTTPS listener
#Secondary Region
resource "aws_acm_certificate_validation" "cert_validation_2nd" {
  provider                = aws.London
  certificate_arn         = aws_acm_certificate.cert_2nd.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_2nd : record.fqdn]
}