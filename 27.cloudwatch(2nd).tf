#Log group 
#Secondary Region
resource "aws_cloudwatch_log_group" "app_logs_2nd" {
  provider          = aws.London
  name              = "/aws/ec2/application"
  retention_in_days = 7 # Automatically deletes logs older than 7 days to save costs
}

# CPU Utilization Alarm
#Secondary Region
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_2nd" {
  provider            = aws.London
  alarm_name          = "ASG_CPU_Utilization_London"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "GroupAverageCPUUtilization"
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