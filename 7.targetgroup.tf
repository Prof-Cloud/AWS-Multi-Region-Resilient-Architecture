# Create a target group for the ALB
resource "aws_lb_target_group" "app_tg" {
  name        = "primary-tg-test"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.primary_vpc.id



  #Critical for fast failover
  deregistration_delay = 30 #default is 300 sec

  health_check {
    # CHANGE THIS: Match the file created in userdata
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 5 # Faster interval for testing
    timeout             = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = {
    Name = "Target Group"
  }
  lifecycle {
    create_before_destroy = true
  }

}