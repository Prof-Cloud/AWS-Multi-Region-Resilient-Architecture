#Route53 Hosted Zone
#I have an existing hosted zone
data "aws_route53_zone" "hosted_zone" {
  name         = var.domain_name
  private_zone = false
}

#Route 53 DNS validation records for ACM
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]

  #Prevent duplicates if record already exists
  lifecycle {
    prevent_destroy = false
  }

  allow_overwrite = true
}


#Health check for primary region
resource "aws_route53_health_check" "primary" {
  fqdn                    = aws_lb.primary_alb.dns_name
  port                    = 80
  type                    = "HTTP"
  resource_path           = "/health"

  failure_threshold       = 2 
  request_interval        = 10

  # This ensures the health check is monitored from multiple global locations
  measure_latency   = true
  
  cloudwatch_alarm_region = "us-east-1"
  cloudwatch_alarm_name   = "primary-health-check"
  depends_on              = [aws_lb.primary_alb]

  tags = {
    Name = "Primary Region Health Check"
  }
}

#Creating DNS record on Route53  - Primary
resource "aws_route53_record" "primary" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = var.domain_name
  type    = "A"


  set_identifier = "primary"
  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary.id

  alias {
    name                   = aws_lb.primary_alb.dns_name
    zone_id                = aws_lb.primary_alb.zone_id
    evaluate_target_health = true # Key for automatic detection
  }
}

#Creating DNS record on Route53  - Secondary
resource "aws_route53_record" "secondary" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = var.domain_name
  type    = "A"

  set_identifier = "secondary"
  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = aws_lb.secondary_alb_2nd.dns_name
    zone_id                = aws_lb.secondary_alb_2nd.zone_id
    evaluate_target_health = true # Key for automatic detection
  }
}

#WWW Record
#Connecting domain to LB
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = "www.${var.domain_name}"
  type - "CNAME"
  ttl = "60"
  records = [var.domain]


  #This is why the falilover policy isnt working. This is an simple aliis that points directly to Virginia LB.
  #Change the www record to a Cname that point to your domain
  #type    = "A"

  alias {
    name                   = aws_lb.primary_alb.dns_name
    zone_id                = aws_lb.primary_alb.zone_id
    evaluate_target_health = true
  }
}

#Create the DNS records for validation for London
#Route 53 is global, so no regional provider is needed here.
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
