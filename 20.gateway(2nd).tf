# Internet Gateway
#Secondary Region
resource "aws_internet_gateway" "igw_2nd" {
  provider = aws.London
  vpc_id   = aws_vpc.secondary_vpc.id

  tags = {
    Name = "Secondary VPC Internet Gateway"
  }
}

#Elastic IP for NAT
#Secondary Region
resource "aws_eip" "maineip_2nd" {
  provider = aws.London
  domain   = "vpc"

  depends_on = [aws_internet_gateway.igw_2nd]

  tags = {
    Name = "Secondary VPC Elastic EIP"
  }
}

#NAT Gateway
#Secondary Region
resource "aws_nat_gateway" "nat_2nd" {
  provider      = aws.London
  allocation_id = aws_eip.maineip_2nd.id

  #Use the first public subnet
  subnet_id = aws_subnet.public_subnet_2nd[0].id

  depends_on = [aws_internet_gateway.igw_2nd]

  tags = {
    Name = "Secondary VPC NAT Gateway"
  }
}