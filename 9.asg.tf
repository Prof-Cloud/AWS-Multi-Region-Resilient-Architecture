#Creates Auto Scaling 
resource "aws_autoscaling_group" "app_asg" {

  min_size            = 3
  max_size            = 9
  desired_capacity    = 6
  vpc_zone_identifier = aws_subnet.private_subnet[*].id

  #Set a specific name that matches the Launch Template variable
  name                = "vanish-app-asg-primary"

  #Health check
  health_check_type         = "ELB"

  #To get Lodon region live faster, reduce the grace period
  health_check_grace_period = 40
  force_delete              = true
  target_group_arns         = [aws_lb_target_group.app_tg.arn]

  launch_template {
    id      = aws_launch_template.app_template.id
    version = "$Latest"
  }

  enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]

  # Instance protection for launching
  initial_lifecycle_hook {
    name                 = "await-userdata"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 300 # Wait up to 5 mins for UserData to finish
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  }
}

# Auto Scaling Policy
resource "aws_autoscaling_policy" "asg_policy" {
  name                   = "app1-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name

  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 120

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 75.0
  }
}
