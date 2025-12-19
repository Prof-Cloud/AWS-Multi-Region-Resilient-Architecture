#Public Subnets
resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_ciders)

  vpc_id            = aws_vpc.primary_vpc.id
  cidr_block        = var.public_subnet_ciders[count.index]
  availability_zone = data.aws_availability_zones.az[count.index]

  tags = {
    Name = "Primary Public Subnet ${count.index + 1}"
    AZ   = "data.aws_availability_zone ${count.index}"
  }
}


#Private Subnets

resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet_ciders)

  vpc_id            = aws_vpc.primary_vpc.id
  cidr_block        = var.private_subnet_ciders[count.index]
  availability_zone = data.aws_availability_zones.az[count.index]

  tags = {

    Name = "Primary Private Subnet ${count.index + 1}"
    AZ   = "data.aws_availability_zone ${count.index}"
  }
}