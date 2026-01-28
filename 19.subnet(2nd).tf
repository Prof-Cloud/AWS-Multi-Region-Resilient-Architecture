#Public Subnets
#Secondary Region
resource "aws_subnet" "public_subnet_2nd" {
  provider = aws.London
  count    = length(var.public_subnet_ciders_2nd)

  vpc_id            = aws_vpc.secondary_vpc.id
  cidr_block        = var.public_subnet_ciders_2nd[count.index]
  availability_zone = data.aws_availability_zones.az_2nd.names[count.index]

  tags = {
    Name = "Primary Public Subnet ${count.index + 1}"
    AZ   = data.aws_availability_zones.az_2nd.names[count.index]
  }
}


#Private Subnets
#Secondary Region
resource "aws_subnet" "private_subnet_2nd" {
  provider = aws.London
  count    = length(var.private_subnet_ciders_2nd)

  vpc_id            = aws_vpc.secondary_vpc.id
  cidr_block        = var.private_subnet_ciders_2nd[count.index]
  availability_zone = data.aws_availability_zones.az_2nd.names[count.index]

  tags = {
    Name = "Primary Private Subnet ${count.index + 1}"
    AZ   = data.aws_availability_zones.az_2nd.names[count.index]
  }
}

#Database Subnets
#Secondary Region
resource "aws_subnet" "db_subnet_2nd" {
  provider = aws.London
  count    = length(var.db_subnet_ciders)

  vpc_id            = aws_vpc.secondary_vpc.id
  cidr_block        = var.db_subnet_ciders_2nd[count.index]
  availability_zone = data.aws_availability_zones.az_2nd.names[count.index]

  tags = {
    Name = "DB Subnet ${count.index + 1}"
    AZ   = data.aws_availability_zones.az_2nd.names[count.index]
  }
}


