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

# Policy DB failover and CloudWatch Logging
resource "aws_iam_role_policy" "lambda_failover_policy" {
  name = "lambda_failover_and_logging"
  role = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:FailoverGlobalCluster",
          "rds:DescribeDBClusters",
          "rds:DescribeGlobalClusters",
          "rds:ModifyGlobalCluster"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}
#Lambda Code
#Zips up python code into a zip file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "failover_lambda.py"
  output_path = "lambda_function_payload.zip"
}

#Lambda Configuration
resource "aws_lambda_function" "failover_logic" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "aurora_failover_guard"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "failover_lambda.lambda_handler"
  runtime       = "python3.12"


  #Failover can take time; 15 mins is the max allowed
  timeout = 900

  # Giving the Lambda the DB names to watch
  environment {
    variables = {
      GLOBAL_CLUSTER_ID = aws_rds_global_cluster.global_db.id
      TARGET_CLUSTER_ID = aws_rds_cluster.secondary_cluster.cluster_identifier
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