#Create an SNS Topic to send alerts
resource "aws_sns_topic" "alerts" {
  name = "website-alerts"
}
##Add  email alert
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "the.fire.dragon.mac@gmail.com"
}

#Create SNS topic for Route 53 failover notifications
resource "aws_sns_topic" "route53_failover_alerts" {
  name = "getvanish-route53-failover"
}

# Email subscription for failover alerts
resource "aws_sns_topic_subscription" "route53_failover_email" {
  topic_arn = aws_sns_topic.route53_failover_alerts.arn
  protocol  = "email"
  endpoint  = "the.fire.dragon.mac@gmail.com"
}