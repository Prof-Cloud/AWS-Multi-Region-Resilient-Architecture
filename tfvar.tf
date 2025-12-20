#CIDR Block
variable "vpc_cidr" {
  type    = string
  default = "10.53.0.0/16"
}

#Public Subnets
variable "public_subnet_ciders" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.53.1.0/24", "10.53.2.0/24", "10.53.3.0/24"]
}

#Private Subnets
variable "private_subnet_ciders" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.53.11.0/24", "10.53.12.0/24", "10.53.13.0/24"]
}

#To ensure each pair of subnet is included per AZ (North Virginia)
data "aws_availability_zones" "az" {
  state = "available"
}

#AMI for Amazon Linux
data "aws_ami" "linux_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}
