#Allows EC2 to assume this role
#This role will be assumed by ec2 in Primary Region
# Allows EC2 to assume this role
resource "aws_iam_role" "ec2_role" {
  name = "ec2-cloudwatch-logs-role"


  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
    }
  )
}

# IAM policy for the EC2 instances to communicate with AWS Services
resource "aws_iam_role_policy" "ec2_asg_signal" {
  name = "ec2_asg_signal_policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      #Permission for the Lifecycle Hook Signal
      # This allows the instance to tell the ASG 'I am ready' at the end of userdata
      {
        Effect   = "Allow"
        Action   = "autoscaling:CompleteLifecycleAction"
        Resource = "*" # Or scope to your specific ASG ARNs
      }
    ]
  })
}


#Attach the Managed Policy for Cloudwatch Logs
#Allows ec2 to send metrics and logs to Cloudwatch
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#Create the Instance Profile  
#Attach IAM role to ec2 for runtume permissions
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-cloudwatch-instance-profile"
  role = aws_iam_role.ec2_role.name
}


#DB

#Get the secret details automatically created by Secret Manager
data "aws_secretsmanager_secret" "db_secret" {
  arn = aws_secretsmanager_secret.db_secret.arn
}

#IAM policy to allow ec2 to read DB secrets
resource "aws_iam_role_policy" "read_db_secret" {
  name = "allow-read-db-secret"
  role = aws_iam_role.ec2_role.id # Link to your existing IAM role

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = data.aws_secretsmanager_secret.db_secret.arn
      }
    ]
  })
}

#IAM policy for S3 log access
#allow ec2 to write logs to its designed S3 bucket
resource "aws_iam_role_policy" "s3_log_write" {
  name = "allow-s3-log-writing"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:PutObject", "s3:GetBucketAcl"]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.log_bucket.arn,
          "${aws_s3_bucket.log_bucket.arn}/*"
        ]
      }
    ]
  })
}
