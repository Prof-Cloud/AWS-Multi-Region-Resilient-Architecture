# Create Load Balancer
#This is an internet facing ALB
resource "aws_lb" "primary_alb" {
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg.id]
  subnets                    = aws_subnet.public_subnet[*].id
  enable_deletion_protection = false

  #Enable access logs and store them in S3
  access_logs {
    bucket  = aws_s3_bucket.log_bucket.bucket
    prefix  = "alb-logs"
    enabled = true
  }

  tags = {
    Name = "Load Balancer"
  }
}


#Create HTTPS Listerner for ALB 
#This Listens traffic on Port 443 and forwards it to the primary target group
resource "aws_lb_listener" "https_front_end" {
  load_balancer_arn = aws_lb.primary_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.cert.arn

  # Wait for validation
  depends_on = [aws_acm_certificate_validation.cert_validation]

  #The default is to forward traffic to the primary EC2 instsnces
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

#Redirect HTTP to HTTPS
#Ensure all users are redirected to secure HTTPS URL
resource "aws_lb_listener" "http_primary" {
  load_balancer_arn = aws_lb.primary_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301" # Permanent redirect
    }
  }
}