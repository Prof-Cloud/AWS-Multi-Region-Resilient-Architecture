#Secondary Region
resource "aws_vpc" "secondary_vpc" {
  cidr_block           = var.vpc_cidr_2nd
  enable_dns_hostnames = true
  enable_dns_support   = true

  provider = aws.London

  tags = {
    Name = "Secondary Region VPC"
  }
}
