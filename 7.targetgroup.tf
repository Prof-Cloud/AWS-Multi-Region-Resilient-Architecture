# Create a target group for the ALB
resource "aws_lb_target_group" "app_tg" {
  name        = "primary-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.primary_vpc.id

  # Create health check for the ALB
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = {
    Name = "Target Group"
  }
}