#Create VPC Flow Logs
#Secondary Region
resource "aws_flow_log" "vpc_flow_2nd" {
  provider                 = aws.London
  log_destination          = aws_s3_bucket.log_bucket2.arn
  log_destination_type     = "s3"
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.secondary_vpc.id
  max_aggregation_interval = 60

  tags = {
    Name = "Secondary VPC Flow Logs"
  }
}


