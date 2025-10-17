##########################################################################
# 작업 순서
# * VPC 생성
# * IGW 생성 및 VPC에 연결
# * Public Subnet
# * Routing Table 생성 및 Public Subnet에 연결
##########################################################################

#
# Provider 설정
#
provider "aws" {
  region = "us-east-2"
}


# 
# VPC 생성
#
resource "aws_vpc" "myVPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "myVPC"
  }
}

# 
# IGW 생성 및 VPC에 연결
#
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}


# 
# Public Subnet
#
resource "aws_subnet" "myPubSN" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "myPubSN"
  }
}

# 
# Routing Table 생성 및 Public Subnet에 연결
#
resource "aws_route_table" "myPubRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = "myPubRT"
  }
}

resource "aws_route_table_association" "myPubRTassociation" {
  subnet_id      = aws_subnet.myPubSN.id
  route_table_id = aws_route_table.myPubRT.id
}

#
# 보안그룹 생성
#
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "allow_web"
  }
}

resource "aws_vpc_security_group_ingress_rule" "mySGhttps" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "mySGhttp" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "mySGeg" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#
# EC2 생성 및 VPC, 네트워크 설정
#
resource "aws_instance" "myEC2" {
  ami           = "ami-077b630ef539aa0b5" 
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.myPubSN.id
  vpc_security_group_ids = [aws_security_group.allow_web.id]

  user_data_replace_on_change = true
  user_data                   = <<-EOF
#!/bin/bash
yum -y install httpd
echo 'MyWEB' > /var/www/html/index.html
systemctl enable --now httpd
EOF

  tags = {
    Name = "myEC2"
  }  

}



