#Public Route Table 
#Public subnets to IGW
#Secondary Region
resource "aws_route_table" "public_2nd" {
  provider = aws.London
  vpc_id   = aws_vpc.secondary_vpc.id
}

#Private Route Table 
#Private subnets to NAT Gateway
#Secondary Region
resource "aws_route_table" "private_2nd" {
  provider = aws.London
  vpc_id   = aws_vpc.secondary_vpc.id
}

# Public route to internet gateway
#Secondary Region
resource "aws_route" "public_internet_2nd" {
  provider               = aws.London
  route_table_id         = aws_route_table.public_2nd.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_2nd.id
}

# Private route to NAT gateway
#Secondary Region
resource "aws_route" "private_nat_2nd" {
  provider               = aws.London
  route_table_id         = aws_route_table.private_2nd.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_2nd.id

  # Ensure the London NAT Gateway is fully functional before creating the route
  depends_on = [aws_nat_gateway.nat_2nd]
}

# Route table associations for public subnets
#Secondary Region
resource "aws_route_table_association" "public_2nd" {
  provider       = aws.London
  count          = length(var.public_subnet_ciders_2nd)
  subnet_id      = aws_subnet.public_subnet_2nd[count.index].id
  route_table_id = aws_route_table.public_2nd.id
}

# Route table associations for private subnets
#Secondary Region
resource "aws_route_table_association" "private_2nd" {
  provider       = aws.London
  count          = length(var.private_subnet_ciders_2nd)
  subnet_id      = aws_subnet.private_subnet_2nd[count.index].id
  route_table_id = aws_route_table.private_2nd.id
}