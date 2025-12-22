# Create Load Balancer
resource "aws_lb" "primary_alb" {
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.Linux_Server.id]
  subnets                    = aws_subnet.public_subnet[*].id
  enable_deletion_protection = false

  #Enable access logs to S3
  access_logs {
    bucket  = aws_s3_bucket.log_bucket.bucket
    prefix  = "alb-logs"
    enabled = true
  }

  tags = {
    Name = "Load Balance"
  }
}

# # Create health check for the Load balancer
resource "aws_lb_target_group" "alb-tg" {
  name        = "instance-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.primary_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

#Create the Listerner for Primary ALB 
#This handle traffic on Port 80 and forwards it to the primary target group
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.primary_alb.arn
  port              = 80
  protocol          = "HTTP"

  #The default is to forward traffic to the primary EC2 instsnces
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg.arn
  }
}