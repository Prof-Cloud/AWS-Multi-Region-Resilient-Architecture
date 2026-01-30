#Attach the Policy to the Log Bucket
#Secondary Region
resource "aws_s3_bucket_policy" "allow_logs_2nd" {
  provider   = aws.London
  bucket     = aws_s3_bucket.log_bucket2.id
  depends_on = [time_sleep.wait_for_s3_propagation] #Forced pause

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # --- ALLOW ALB LOGS ---
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::652711504416:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.log_bucket2.arn}/alb-logs-london/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },

      # --- ALLOW VPC FLOW LOGS ---
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.log_bucket2.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      # --- ALLOW LOG DELIVERY TO CHECK BUCKET ---
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.log_bucket2.arn
      }
    ]
  })
}
data "aws_caller_identity" "current" {}

# Add this to your 30.s3(2nd).tf
resource "time_sleep" "wait_30_seconds" {
  depends_on      = [aws_s3_bucket.log_bucket2]
  create_duration = "30s"
}