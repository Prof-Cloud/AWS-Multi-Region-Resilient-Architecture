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

#Private Subnets - Database
variable "db_subnet_ciders" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.53.101.0/24", "10.53.102.0/24", "10.53.103.0/24"]
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

#Domain name
variable "domain_name" {
  default = "getvanish.io"
}

#ttl
variable "dns_record_ttl" {
  default     = 600
  type        = number
  description = "TTL for DNS records"
}

#Health Check
variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/health"
}

#S3 Bucket name
variable "bucket_name" {
  default = "logbucketprojcloud"
}

#Secondary Region
#London

#CIDR Block - Secondary
variable "vpc_cidr_2nd" {
  type    = string
  default = "10.30.0.0/16"
}

#Public Subnets - Secondary
variable "public_subnet_ciders_2nd" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.30.1.0/24", "10.30.2.0/24", "10.30.3.0/24"]
}

#Private Subnets - Secondary
variable "private_subnet_ciders_2nd" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.30.11.0/24", "10.30.12.0/24", "10.30.13.0/24"]
}

#Private Subnets - Database
variable "db_subnet_ciders_2nd" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.30.101.0/24", "10.30.102.0/24", "10.30.103.0/24"]
}

#To ensure each pair of subnet is included per AZ (Dubai)
data "aws_availability_zones" "az_2nd" {
  state    = "available"
  provider = aws.London
}


#AMI for Amazon Linux
data "aws_ami" "linux_ami_2nd" {
  provider    = aws.London
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

#S3 Bucket name - Secondary
variable "bucket_name2" {
  default = "logbucketprojcloudlondon"
}