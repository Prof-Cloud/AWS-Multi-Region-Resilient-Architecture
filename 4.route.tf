#Public Route Table 
#Public subnets to IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.primary_vpc.id
}

#Private Route Table 
#Private subnets to NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.primary_vpc.id
}

# Public route to internet gateway
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Private route to NAT gateway
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id

  # Ensure the NAT Gateway is fully functional before creating the route
  depends_on = [aws_nat_gateway.nat]
}

# Route table associations for public subnets
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_ciders)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route table associations for private subnets
resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_ciders)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private.id
}