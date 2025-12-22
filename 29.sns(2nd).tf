# This topic stays in London to catch London Alarms
resource "aws_sns_topic" "alerts_2nd" {
  provider = aws.London
  name     = "website-alerts-london"
}

resource "aws_sns_topic_subscription" "email_alert_2nd" {
  provider  = aws.London
  topic_arn = aws_sns_topic.alerts_2nd.arn
  protocol  = "email"
  endpoint  = "the.fire.dragon.mac@gmail.com"
}