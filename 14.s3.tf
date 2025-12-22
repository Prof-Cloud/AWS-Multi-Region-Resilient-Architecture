# S3 Bucket to store VPC Flow Logs, ALB Logs, and EC2 logs
resource "aws_s3_bucket" "log_bucket" {
  bucket = var.bucket_name

  tags = {
    Name = "S3 Robot"
  }
  #Allow terraform to delete the bucket even if files exist in the bucket
  force_destroy = true
}

#SSE
resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_sse" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#Enabling bucket or no rules automatically
resource "aws_s3_bucket_ownership_controls" "Drop_off_ownership" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

#Making S3 bucket private
resource "aws_s3_bucket_public_access_block" "access_block" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#Bucket versioning
resource "aws_s3_bucket_versioning" "S3_versioning" {
  bucket = aws_s3_bucket.log_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

#Lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "S3-lifecycle" {
  bucket = aws_s3_bucket.log_bucket.id

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
