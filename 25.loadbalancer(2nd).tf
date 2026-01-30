# Create Load Balancer
#Secondary Region
resource "aws_lb" "secondary_alb_2nd" {
  provider                   = aws.London
  name                       = "london-alb"
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

#Redirect HTTP to HTTPS
#Ensure all users are redirected to secure HTTPS URL
resource "aws_lb_listener" "http_2nd" {
  provider          = aws.London
  load_balancer_arn = aws_lb.secondary_alb_2nd.arn
  port              = 80
  protocol          = "HTTP"

  # Direct forward for testing; no redirect to 443 yet
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}



#Create HTTPS Listerner for ALB 
#This Listens traffic on Port 443 and forwards it to the secondary target group
resource "aws_lb_listener" "https_2nd" {
  provider          = aws.London
  load_balancer_arn = aws_lb.secondary_alb_2nd.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.cert_2nd.arn

  #Ensure the certificate is actually valid before creating the listener
  depends_on = [aws_acm_certificate_validation.cert_validation_2nd]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg_2nd.arn
  }
}

