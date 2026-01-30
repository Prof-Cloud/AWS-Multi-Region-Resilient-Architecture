#Primary Region (Virginia)
#Allos private access to s3 without using public internet
resource "aws_vpc_endpoint" "s3_primary" {
  vpc_id            = aws_vpc.primary_vpc.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

  # Automatically add the route to your private/public route tables
  route_table_ids = [aws_route_table.public.id, aws_route_table.private.id]

  tags = {
    Name = "S3-Endpoint-Primary"
  }
}

#Secondary Region (London) 
resource "aws_vpc_endpoint" "s3_secondary" {
  provider          = aws.London
  vpc_id            = aws_vpc.secondary_vpc.id
  service_name      = "com.amazonaws.eu-west-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.public_2nd.id, aws_route_table.private_2nd.id]

  tags = {
    Name = "S3-Endpoint-Secondary"
  }
}