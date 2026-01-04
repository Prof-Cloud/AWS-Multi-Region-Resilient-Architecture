# Create a target group for the ALB
#Secondary Region
resource "aws_lb_target_group" "alb_tg_2nd" {
  provider    = aws.London
  name        = "tg-london"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.secondary_vpc.id

  # Create health check for the ALB
  #Secondary Region
  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = {
    Name = "Target Group - Secondary Region"
  }
  lifecycle {
    create_before_destroy = true
  }
}