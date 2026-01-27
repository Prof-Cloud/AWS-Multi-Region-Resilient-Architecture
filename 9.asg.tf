#Creates Auto Scaling 
resource "aws_autoscaling_group" "app_asg" {

  min_size            = 3
  max_size            = 9
  desired_capacity    = 6
  vpc_zone_identifier = aws_subnet.private_subnet[*].id

  #Set a specific name that matches the Launch Template variable
  name = "vanish-app-asg-primary"

  #Health check
  health_check_type = "ELB"

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
  #This keeps the instance in 'Pending:Wait' until UserData signals
  initial_lifecycle_hook {
    name                 = "await-userdata"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 300 # Wait up to 5 mins for UserData to finish
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  }

# Instance Refresh Block
  # This prevents 503 errors by ensuring new instances are ready before old ones die.
  instance_refresh {
    strategy = "Rolling"
    preferences {
      # Percentage of the ASG that must remain 'InService' and 'Healthy' during a refresh.
      # Setting this to 50% means 3 out of your 6 desired instances stay alive.
      min_healthy_percentage = 50
      
      # Time to wait after an instance is 'InService' before moving to the next one.
      instance_warmup = 300 
    }
    # Refresh will trigger if the Launch Template or UserData changes.
    triggers = ["tag"] 
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
