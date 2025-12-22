#Allows EC2 to assume this role
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
  })

}

#Attach the Managed Policy for Cloudwatch Logs
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#Create the Instance Profile  (attach to EC2)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-cloudwatch-instance-profile"
  role = aws_iam_role.ec2_role.name
}


#DB
#Get the secret details automatically created by Secret Manager
data "aws_secretsmanager_secret" "db_secret" {
  arn = aws_secretsmanager_secret.db_secret.arn
}

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
