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

#Primary Region Health Check 
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

  tags = {
    Name = "Primary Region Health Check - EC2 Alarm"
  }
}

# Child Check 2: Monitors the Latency (2xx Warnings) Alarm
resource "aws_route53_health_check" "child_high_latency" {
  type                            = "CLOUDWATCH_METRIC"
  cloudwatch_alarm_name           = aws_cloudwatch_metric_alarm.high_latency.alarm_name
  cloudwatch_alarm_region         = "us-east-1"
  insufficient_data_health_status = "Unhealthy"

  tags = {
    Name = "Primary Region Health Check - Latency"
  }
}

#Secondary Region Health Check 
#Health check for secondary region
resource "aws_route53_health_check" "secondary" {
  # HTTP check against /health page of London ALB
  type          = "HTTPS"
  port          = 443
  resource_path = "/health"

  request_interval  = 30
  failure_threshold = 3

  fqdn = aws_lb.secondary_alb_2nd.dns_name

  # This ensures it ignores SSL certificate name mismatches during health checks
  measure_latency   = true

  tags = {
    Name = "Secondary Region Health Check - London"
  }
}

#Primary Region
#Creating DNS record on Route53
resource "aws_route53_record" "primary" {
  zone_id        = data.aws_route53_zone.hosted_zone.zone_id
  name           = var.domain_name
  type           = "A"
  set_identifier = "primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  #Cloudwatch based health check, not ALB
  health_check_id = aws_route53_health_check.primary.id

  alias {
    name    = aws_lb.primary_alb.dns_name
    zone_id = aws_lb.primary_alb.zone_id

    #Should be true to let Route53 detect failures
    #True, allow Route53 to detect ALB/TF health and trigger failover
    evaluate_target_health = true
  }
}

#Secondary Region
#Creating DNS record on Route53 
resource "aws_route53_record" "secondary" {
  zone_id        = data.aws_route53_zone.hosted_zone.zone_id
  name           = var.domain_name
  type           = "A"
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

#www Record Primary
#Connecting domain to LB
resource "aws_route53_record" "www_primary" {
  zone_id        = data.aws_route53_zone.hosted_zone.zone_id
  name           = "www.${var.domain_name}"
  type           = "A"
  set_identifier = "www-primary"


  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary.id


  alias {
    # This points 'www' to the 'primary' record logic above
    name                   = aws_lb.primary_alb.dns_name
    zone_id                = aws_lb.primary_alb.zone_id
    
    #Must be true for failover to work
    evaluate_target_health = true
  }

}

#www Record Secondary
resource "aws_route53_record" "www_secondary" {
  zone_id        = data.aws_route53_zone.hosted_zone.zone_id
  name           = "www.${var.domain_name}"
  type           = "A" # Change from CNAME to A
  set_identifier = "www-secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }

  health_check_id = aws_route53_health_check.secondary.id

  alias {
    # This points 'www' to the 'primary' record logic above
    name                   = aws_lb.secondary_alb_2nd.dns_name
    zone_id                = aws_lb.secondary_alb_2nd.zone_id

    #Ensure Route53 knows this ALB is healthy
    evaluate_target_health = true
  }
}
