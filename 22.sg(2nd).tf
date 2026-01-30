#ALB Security Group
resource "aws_security_group" "alb_sg_2nd" {
  provider    = aws.London
  name        = "alb-sg"
  description = "Security group for ALB Secondary Region"
  vpc_id      = aws_vpc.secondary_vpc.id

  tags = {
    Name = "ALB Security Group Secondary Group"
  }
}

#Aloow HTTP from the Internet 
resource "aws_vpc_security_group_ingress_rule" "alb_http_2nd" {
  provider          = aws.London
  security_group_id = aws_security_group.alb_sg_2nd.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_2nd" {
  provider          = aws.London
  security_group_id = aws_security_group.alb_sg_2nd.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

#ALB Outbound Rules 
resource "aws_vpc_security_group_egress_rule" "alb_outbound_2nd" {
  provider          = aws.London
  security_group_id = aws_security_group.alb_sg_2nd.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#Security Group for Linux Server
#Secondary Region
resource "aws_security_group" "Linux_Server_2nd" {
  provider    = aws.London
  name        = "Linux_Server_2nd"
  description = "Allow HTTP inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.secondary_vpc.id

  tags = {
    Name = "Linux Server SG Secondary"
  }
}

#Inbound Rules Allws HTTP from ALB
#Secondary Region
resource "aws_vpc_security_group_ingress_rule" "ec2_from_alb_2nd" {
  provider                     = aws.London
  security_group_id            = aws_security_group.Linux_Server_2nd.id
  referenced_security_group_id = aws_security_group.alb_sg_2nd.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}

resource "aws_vpc_security_group_ingress_rule" "Linux_Server_ssh_2nd" {
  provider          = aws.London
  security_group_id = aws_security_group.Linux_Server_2nd.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


#Outbound Rules
#Secondary Region
resource "aws_vpc_security_group_egress_rule" "Linux_Server_allow_all_traffic_ipv4_2nd" {
  provider          = aws.London
  security_group_id = aws_security_group.Linux_Server_2nd.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#Database SG
#Secondary Region
resource "aws_security_group" "db_sg_2nd" {
  provider    = aws.London
  name        = "Aurora DB SG_2nd"
  description = "Aurora Security Group"
  vpc_id      = aws_vpc.secondary_vpc.id

  tags = {
    Name = "Aurora DB SG Secondary Region"
  }
}

#Inbound Rules. - ALlow Aurura(mySQL) from  the EC2 SG
resource "aws_vpc_security_group_ingress_rule" "db_ingress_2nd" {
  provider          = aws.London
  security_group_id = aws_security_group.db_sg_2nd.id

  #This links the DB access directly to the EC2
  referenced_security_group_id = aws_security_group.Linux_Server_2nd.id


  from_port   = 3306 #Use 5432 if using PostgreSQL
  ip_protocol = "tcp"
  to_port     = 3306
}



#Outbound Database
# Outbound for Secondary DB
resource "aws_vpc_security_group_egress_rule" "db_egress_2nd" {
  provider          = aws.London
  security_group_id = aws_security_group.db_sg_2nd.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#SG - S3 VPC ENdpoints
# Allow Linux to send logs to S3 (Secondary)
resource "aws_vpc_security_group_egress_rule" "allow_s3_logs_2nd" {
  provider          = aws.London
  security_group_id = aws_security_group.Linux_Server_2nd.id
  prefix_list_id    = aws_vpc_endpoint.s3_secondary.prefix_list_id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
