# Wait until Aurora metrics exist
resource "time_sleep" "wait_for_db_metrics" {

  # Wait until at least one DB instance is fully running
  depends_on = [aws_rds_cluster_instance.primary_instances]

  # Give CloudWatch time to publish RDS metrics
  create_duration = "180s"

}

#Primary Failover Alarm
# This alarm triggers the SNS → Lambda failover
# Uses replica lag instead of connection count
# This avoids false positives during scale events
resource "aws_cloudwatch_metric_alarm" "aurora_primary_failure" {
  alarm_name        = "aurora-primary-failure"
  alarm_description = "Primary Aurora cluster is unavailable"

  namespace   = "AWS/RDS"
  metric_name = "AuroraReplicaLagMaximum"
  statistic   = "Maximum"
  period      = 60

  # Short evaluation window for demo speed
  evaluation_periods  = 2
  threshold           = 600
  comparison_operator = "GreaterThanThreshold"

  ## Aurora Global DB may emit no data when idle
  treat_missing_data = "notBreaching"

  # Monitor the PRIMARY cluster only
  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.primary_cluster.id
  }

  # Ensure metrics exist before creating the alarm
  depends_on = [
    time_sleep.wait_for_db_metrics
  ]

  # Trigger failover Lambda via SNS
  alarm_actions = [
    aws_sns_topic.db_failover_topic.arn
  ]
}


