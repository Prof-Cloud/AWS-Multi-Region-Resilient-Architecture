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