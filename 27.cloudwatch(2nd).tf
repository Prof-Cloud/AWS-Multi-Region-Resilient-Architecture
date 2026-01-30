
#Cloudwatch - 0 EC2 alarm
#Secondary Region
#Watches the Primary Target Group and sounds the alarm if EC2s are deleted.
resource "aws_cloudwatch_metric_alarm" "no_healthy_hosts_2nd" {
  provider            = aws.London
  alarm_name          = "secondary-tg-no-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"

  dimensions = {
    TargetGroup  = aws_lb_target_group.alb_tg_2nd.arn_suffix
    LoadBalancer = aws_lb.secondary_alb_2nd.arn_suffix
  }

  alarm_description  = "Fails if London target group is empty"
  treat_missing_data = "breaching"
}

# Cloudwatch - High Latency Alarm
#Secondary Region
# This catches the 2xx warnings, site is up but responding too slowly
resource "aws_cloudwatch_metric_alarm" "high_latency_2nd" {
  provider            = aws.London
  alarm_name          = "secondary-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "2.0"

  dimensions = {
    LoadBalancer = aws_lb.secondary_alb_2nd.arn_suffix
  }

  alarm_description  = "Fails if London app is crawling/slow"
  treat_missing_data = "notBreaching"
}

# CPU Utilization Alarm
#Secondary Region
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_2nd" {
  provider            = aws.London
  alarm_name          = "ASG_CPU_Utilization_London"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm if ASG CPU > 80% for 10 minutes"
  treat_missing_data  = "notBreaching"

  #Monitor the Whole ASG 
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg_2nd.name
  }

  alarm_actions = [aws_sns_topic.alerts_2nd.arn]
}

# Network In Alarm
#Secondary Region
resource "aws_cloudwatch_metric_alarm" "ec2_network_in_2nd" {
  provider            = aws.London
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
    AutoScalingGroupName = aws_autoscaling_group.app_asg_2nd.name
  }
  alarm_actions = [aws_sns_topic.alerts_2nd.arn]
}


#Log group 
#Secondary Region
resource "aws_cloudwatch_log_group" "app_logs_2nd" {
  provider          = aws.London
  name              = "/aws/ec2/application"
  retention_in_days = 7 # Automatically deletes logs older than 7 days to save costs
}