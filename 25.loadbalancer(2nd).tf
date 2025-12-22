# Create Load Balancer
#Secondary Region
resource "aws_lb" "secondary_alb_2nd" {
  provider                   = aws.London
  name                       = "secondary-tg"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.Linux_Server_2nd.id]
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

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

#Create the Listerner to handle incoming HTTP traffic in London
#Secondary Region
resource "aws_lb_listener" "front_end_2nd" {
  provider          = aws.London
  load_balancer_arn = aws_lb.secondary_alb_2nd.arn #Points to London ALB
  port              = 80
  protocol          = "HTTP"

  #The default command tells the ALB what to do with requests that dont match other rules
  #In this case, we forward to our London Target Group

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg_2nd.arn
  }
}