# CloudWatch alarm for health check
resource "aws_cloudwatch_metric_alarm" "primary_health_check" {
  alarm_name          = "primary-health-check"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "This metric monitors the health check status"
  treat_missing_data  = "breaching"

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary.id
  }

  alarm_actions = [aws_sns_topic.route53_failover_alerts.arn]
  tags = {
    Name = "CloudWatch Primary Health Check"
  }
}

#Log group 
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/application"
  retention_in_days = 7 # Automatically deletes logs older than 7 days to save costs
}

# CPU Utilization Alarm
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