#0 EC2 CloudWatch Alarm
#Watches the Primary Target Group and sounds the alarm if EC2s are deleted.
resource "aws_cloudwatch_metric_alarm" "no_healthy_hosts" {
  alarm_name          = "primary-tg-no-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1" ## If it drops below 1, it's a fail

  dimensions = {
    # This points specifically to your Primary ALB and Target Group
    TargetGroup  = aws_lb_target_group.app_tg.arn_suffix
    LoadBalancer = aws_lb.primary_alb.arn_suffix
  }

  alarm_description = "Fails when there are no EC2s in the primary target group"

  # If the metric disappears (like when you delete the TG), treat it as a failure
  treat_missing_data = "breaching"
}

#High Latency CloudWatch Alarm
# This catches the 2xx warnings, site is up but responding too slowly
resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "primary-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "2.0" # If it takes more than 2 seconds, it's a warning/fail

  # This ensures the alarm clears when instances are gone
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.primary_alb.arn_suffix
  }

  alarm_description  = "Fails if the app is crawling (slow 2xx responses)"

}


#CPU Utilization CloudWatch Alarm
#Montior CPU for ALB
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "EC2_CPU_Utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm if CPU > 80% for 10 minutes"
  treat_missing_data  = "notBreaching"

  #Monitor the Whole ASG 
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

# Network In Alarm
resource "aws_cloudwatch_metric_alarm" "ec2_network_in" {
  alarm_name          = "EC2_Network_In"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 10000000 # adjust as needed
  alarm_description   = "Alarm if NetworkIn exceeds threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}

#Log group 
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/application"
  retention_in_days = 7 # Automatically deletes logs older than 7 days to save costs
}

