#Creates Auto Scaling 
#Secondary Region
resource "aws_autoscaling_group" "app_asg_2nd" {
  provider = aws.London
  name     = "vanish-app-asg-secondary" #Set a specific name that matches the Launch Template variable

  min_size            = 1
  max_size            = 3 #Kept smaller for standby
  desired_capacity    = 2
  vpc_zone_identifier = aws_subnet.private_subnet_2nd[*].id


  #Linking to London Target Group 
  target_group_arns = [aws_lb_target_group.alb_tg_2nd.arn]

  #Health check
  #Secondary Region
  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = true

  launch_template {
    id      = aws_launch_template.app_template_2nd.id
    version = "$Latest"
  }

  #This helps destroy move faster
  wait_for_capacity_timeout = "0"

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
#Secondary Region
resource "aws_autoscaling_policy" "asg_policy_2nd" {
  provider               = aws.London
  name                   = "app1-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.app_asg_2nd.name

  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 120

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 75.0
  }
}
