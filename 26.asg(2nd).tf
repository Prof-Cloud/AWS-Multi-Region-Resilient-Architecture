#Creates Auto Scaling 
#Secondary Region
resource "aws_autoscaling_group" "app_asg_2nd" {
  provider            = aws.London
  name_prefix         = "app_asg_2nd"
  min_size            = 1
  max_size            = 3 #Kept smaller for standby
  desired_capacity    = 2
  vpc_zone_identifier = aws_subnet.private_subnet_2nd[*].id

  #Health check
  #Secondary Region
  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = true
  target_group_arns         = [aws_lb_target_group.tg_london.arn]

  launch_template {
    id      = aws_launch_template.app_template_2nd.id
    version = "$Latest"
  }

  enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]

  # Lifecycle hook for instance launching
  initial_lifecycle_hook {
    name                  = "instance-protection-launch"
    lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
    default_result        = "CONTINUE"
    heartbeat_timeout     = 60
    notification_metadata = "{\"key\":\"value\"}"
  }

  #Comment out for test
  # Instance protection for terminating
  #Secondary Region
  initial_lifecycle_hook {
    name                 = "scale-in-protection"
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 300
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
