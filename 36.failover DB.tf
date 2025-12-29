# SNS Topic
# Create Alert - DB is down
resource "aws_sns_topic" "db_failover_topic" {
  name = "db-failover-notifications"
}

# Sending a message to your email
resource "aws_sns_topic_subscription" "user_email" {
  topic_arn = aws_sns_topic.db_failover_topic.arn
  protocol  = "email"
  endpoint  = "the.fire.dragon.mac@gmail.com"
}

# Cloudwatch
# triggers aalert when databases down
resource "aws_cloudwatch_metric_alarm" "database_health" {
  alarm_name          = "primary-db-is-down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.primary_cluster.id
  }

  #Wait for the DB instances to actually be running
  depends_on = [aws_rds_cluster_instance.primary_instances]

  #When alaram goes off, tell the SNS topic
  alarm_actions = [aws_sns_topic.db_failover_topic.arn]
}

#IAM role
# Giving Lambda permission
resource "aws_iam_role" "lambda_exec_role" {
  name = "failover_guard_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Allowing Lambda to use the RDS failover tool
resource "aws_iam_role_policy" "lambda_rds_policy" {
  role = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["rds:FailoverGlobalCluster", "rds:DescribeDBClusters"]
      Resource = "*"
    }]
  })
}

#Lambda
#Zips up python code into a zip file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "failover_lambda.py"
  output_path = "lambda_function_payload.zip"
}

#Lambda performs the failover
resource "aws_lambda_function" "failover_logic" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "aurora_failover_guard"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "failover_lambda.lambda_handler"
  runtime       = "python3.9"

  # Giving the Lambda the DB names to watch
  environment {
    variables = {
      GLOBAL_CLUSTER_ID  = aws_rds_global_cluster.global_db.id
      TARGET_CLUSTER_ARN = aws_rds_cluster.secondary_cluster.arn
    }
  }
}

#Gives permission to trigger Lambda
resource "aws_lambda_permission" "allow_sns" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.failover_logic.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.db_failover_topic.arn
}

#Connecting SNS topic to Lambda
resource "aws_sns_topic_subscription" "lambda_trigger" {
  topic_arn = aws_sns_topic.db_failover_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.failover_logic.arn
}