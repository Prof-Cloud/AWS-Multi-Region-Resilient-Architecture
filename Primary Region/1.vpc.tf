resource "aws_vpc" "primary_vpc" {
  cidr_block           = var.aws_vpc
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Primary Region VPC"

  }
}
