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

  # This is a "Calculated" check that combines the Host Count and Latency
  type                   = "CALCULATED"
  child_health_threshold = 2 # Both host count AND latency must be good

  child_healthchecks = [
    aws_route53_health_check.child_no_hosts.id,
    aws_route53_health_check.child_high_latency.id
  ]

  tags = {
    Name = "Primary Region Health Check"
  }
}
# Child Check 1: Monitors the 0 EC2 Alarm
resource "aws_route53_health_check" "child_no_hosts" {
  type                            = "CLOUDWATCH_METRIC"
  cloudwatch_alarm_name           = aws_cloudwatch_metric_alarm.no_healthy_hosts.alarm_name
  cloudwatch_alarm_region         = "us-east-1"
  insufficient_data_health_status = "Unhealthy"
}

# Child Check 2: Monitors the Latency (2xx Warnings) Alarm
resource "aws_route53_health_check" "child_high_latency" {
  type                            = "CLOUDWATCH_METRIC"
  cloudwatch_alarm_name           = aws_cloudwatch_metric_alarm.high_latency.alarm_name
  cloudwatch_alarm_region         = "us-east-1"
  insufficient_data_health_status = "Healthy"
}


#Creating DNS record on Route53  - Primary
resource "aws_route53_record" "primary" {
  zone_id        = data.aws_route53_zone.hosted_zone.zone_id
  name           = var.domain_name
  type           = "A"
  set_identifier = "primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary.id

  alias {
    name    = aws_lb.primary_alb.dns_name
    zone_id = aws_lb.primary_alb.zone_id

    #Want Route53 to listen to the 503 error not the ALB status
    evaluate_target_health = true


    #Wrong #Because when I delete the ec2 in virginia, the tg is emply, so the ALB will return a 503 error 
    #The ALB infrastrue is still healthly because "evaluate_target_health = true" is on #Route 53 talking to ALB, ALB is say Yes, I'am running 
    #evaluate_target_health = true
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
  type    = "A" # Change from CNAME to A

  alias {
    # This points 'www' to the 'primary' record logic above
    name                   = aws_route53_record.primary.name
    zone_id                = aws_route53_record.primary.zone_id
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