# Create Load Balancer
#Secondary Region
resource "aws_lb" "secondary_alb_2nd" {
  provider                   = aws.London
  name                       = "secondary-tg"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg_2nd.id]
  subnets                    = aws_subnet.public_subnet_2nd[*].id
  enable_deletion_protection = false

  #Enable access logs to S3
  #Secondary Region
  access_logs {
    bucket  = aws_s3_bucket.log_bucket2.id
    prefix  = "alb-logs-london"
    enabled = true
  }

  tags = {
    Name = "Load Balancer - Secondary Region"
  }
}

#Create health check for the Load balancer
#Secondary Region
resource "aws_lb_target_group" "alb-tg_2nd" {
  provider    = aws.London
  name        = "secondary-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.secondary_vpc.id

  #Critical for fast failover
  deregistration_delay = 30 #default is 300 sec

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

#Create HTTPS Listerner for ALB 
#This Listens traffic on Port 443 and forwards it to the secondary target group
resource "aws_lb_listener" "https_front_end_2nd" {
  provider          = aws.London
  load_balancer_arn = aws_lb.secondary_alb_2nd.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.cert_2nd.arn

  # Wait for validation
  depends_on = [aws_acm_certificate_validation.cert_validation_2nd]

  #The default is to forward traffic to the secondary EC2 instsnces
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg_2nd.arn
  }
}

#Redirect HTTP to HTTPS
#Ensure all users are redirected to secure HTTPS URL
resource "aws_lb_listener" "http_redirect_2nd" {
  provider          = aws.London
  load_balancer_arn = aws_lb.secondary_alb_2nd.arn
  port              = 80
  protocol          = "HTTP"


  #The default is to forward traffic to HTTPS
  default_action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }

  }
  depends_on = [aws_acm_certificate_validation.cert_validation_2nd]
}

