#Create VPC Flow Logs
#Capture all network traffic data for auditing and troubleshooting
resource "aws_flow_log" "vpc_flow" {

  #Store VPC flow logs in s3 bucket
  log_destination      = aws_s3_bucket.log_bucket.arn
  log_destination_type = "s3"

  #Capture all data
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.primary_vpc.id
  max_aggregation_interval = 60

  tags = {
    Name = "Primary VPC Flow Logs"
  }
}


