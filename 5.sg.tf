#Securitty Group For Linux Server 

resource "aws_security_group" "Linux_Server" {
  name        = "Linux_Server"
  description = "Allow HTTP inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.primary_vpc.id

  tags = {
    Name = "Linux Server SG"
  }
}

#Inbound Rules
resource "aws_vpc_security_group_ingress_rule" "Linux_Server_ipv4" {
  security_group_id = aws_security_group.Linux_Server.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "Linux_Server_ssh" {
  security_group_id = aws_security_group.Linux_Server.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

#Outbound Rules
resource "aws_vpc_security_group_egress_rule" "Linux_Server_allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.Linux_Server.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#Database SG
resource "aws_security_group" "db_sg" {
  name        = "Aurora DB SG"
  description = "Aurora Security Group"
  vpc_id      = aws_vpc.primary_vpc.id

  tags = {
    Name = "Aurora DB SG"
  }
}


#Inbound Rules. - ALlow Aurura(mySQL) from  the EC2 SG
resource "aws_vpc_security_group_ingress_rule" "db_ingress" {
  security_group_id = aws_security_group.db_sg.id

  #This links the DB access directly to the EC2
  referenced_security_group_id = aws_security_group.Linux_Server.id


  from_port   = 3306 #Use 5432 if using PostgreSQL
  ip_protocol = "tcp"
  to_port     = 3306
}

#Outbound Database
resource "aws_vpc_security_group_egress_rule" "db_egress" {
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#SG - S3 VPC ENdpoints
# Allow Linux to send logs to S3 (Primary)
resource "aws_vpc_security_group_egress_rule" "allow_s3_logs" {
  security_group_id = aws_security_group.Linux_Server.id
  prefix_list_id    = aws_vpc_endpoint.s3_primary.prefix_list_id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}