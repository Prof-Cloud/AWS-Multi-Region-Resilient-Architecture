#Route53 Hosted Zone
#I have an existing hosted zone

data "aws_route53_zone" "hosted_zone" {
  name         = var.domain_name
  private_zone = false
}

#Health check for primary region
resource "aws_route53_health_check" "primary" {
  fqdn                            = aws_lb.primary_alb.dns_name
  port                            = 80
  type                            = "HTTP"
  resource_path                   = var.health_check_path
  failure_threshold               = 3
  request_interval                = 30
  cloudwatch_alarm_region         = "us-east-1"
  cloudwatch_alarm_name           = "primary-health-check"



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
    evaluate_target_health = true
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
    evaluate_target_health = true
  }
}
