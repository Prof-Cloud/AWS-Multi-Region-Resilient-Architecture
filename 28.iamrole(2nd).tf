#IAM Role for London EC2
#Secondary Region
resource "aws_iam_role" "ec2_role_2nd" {
  provider = aws.London
  name     = "ec2-cloudwatch-logs-role_2nd"


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
  })

}

#Attach the Managed Policy for Cloudwatch Logs
#Secondary Region
resource "aws_iam_role_policy_attachment" "cloudwatch_logs_2nd" {
  provider   = aws.London
  role       = aws_iam_role.ec2_role_2nd.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#Create the Instance Profile  (attach to EC2)
#Secondary Region
resource "aws_iam_instance_profile" "ec2_profile_2nd" {
  provider = aws.London
  name     = "ec2-cloudwatch-instance-profile_2nd"
  role     = aws_iam_role.ec2_role_2nd.name
}

resource "aws_iam_role_policy" "read_db_secret_2nd" {
  provider = aws.London
  name     = "allow-read-db-secret_2nd"
  role     = aws_iam_role.ec2_role_2nd.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = data.aws_secretsmanager_secret.db_secret_2nd.arn
      }
    ]
  })
}

#Database Secret data sources
# We use 'provider = aws' to tell Terraform to look in Virginia.
data "aws_secretsmanager_secret" "db_secret_2nd" {
  provider = aws 
  arn      = aws_secretsmanager_secret.db_secret.arn 
}