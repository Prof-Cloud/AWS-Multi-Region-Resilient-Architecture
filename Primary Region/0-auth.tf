terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.25.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"


  default_tags {
    tags = {
      TeamMember  = "Prof Cloud"
      ManagedBy   = "Terraform"
      Environment = "Dev"
      Location    = "North Virginia"
    }
  }
}

