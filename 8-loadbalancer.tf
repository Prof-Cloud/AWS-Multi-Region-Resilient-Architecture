# Create Load Balancer
resource "aws_lb" "ALB" {
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.Linux_Server.id]
  subnets                    = aws_subnet.public_subnet[*].id
  enable_deletion_protection = false

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