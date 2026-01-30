# S3 Bucket to store VPC Flow Logs, ALB Logs, and EC2 logs
#Secondary Region
resource "aws_s3_bucket" "log_bucket2" {
  provider = aws.London
  bucket   = var.bucket_name2

  tags = {
    Name = "London Log Bucket"
  }
  #Allow terraform to delete the bucket even if files exist in the bucket
  force_destroy = true
}


##Add a 30-second "Cool Down" period
# This gives the AWS Global DNS time to realize the bucket exists in London
resource "time_sleep" "wait_for_s3_propagation" {
  depends_on      = [aws_s3_bucket.log_bucket2]
  create_duration = "30s"
}

#SSE
#Secondary Region
resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket2_sse" {
  provider = aws.London
  bucket   = aws_s3_bucket.log_bucket2.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#Enabling bucket or no rules automatically
#Secondary Region
resource "aws_s3_bucket_ownership_controls" "Drop_off_ownership_2nd" {
  provider = aws.London
  bucket   = aws_s3_bucket.log_bucket2.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

#Making S3 bucket private
#Secondary Region
resource "aws_s3_bucket_public_access_block" "access_block_2nd" {
  provider                = aws.London
  bucket                  = aws_s3_bucket.log_bucket2.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#Bucket versioning
#Secondary Region
resource "aws_s3_bucket_versioning" "S3_versioning_2nd" {
  provider = aws.London
  bucket   = aws_s3_bucket.log_bucket2.id

  versioning_configuration {
    status = "Enabled"
  }
}

#Lifecycle rules
#Secondary Region
resource "aws_s3_bucket_lifecycle_configuration" "S3-lifecycle_2nd" {
  provider = aws.London
  bucket   = aws_s3_bucket.log_bucket2.id

  #depend on the sleep timer, not just the bucket
  depends_on = [time_sleep.wait_for_s3_propagation]

  rule {
    id     = "log-cleanup-London"
    status = "Enabled"

    #Move to S3 IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    #Move to Glacier after 60 days
    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    #Permanently delete logs after 90 days to keep cost low
    expiration {
      days = 90
    }
  }
}
