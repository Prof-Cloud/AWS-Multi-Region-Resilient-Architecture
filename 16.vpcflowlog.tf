#Create VPC Flow Logs
resource "aws_flow_log" "vpc_flow" {
  log_destination          = aws_s3_bucket.log_bucket.arn
  log_destination_type     = "s3"
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.primary_vpc.id
  max_aggregation_interval = 60

  tags = {
    Name = "Primary VPC Flow Logs"
  }
}


