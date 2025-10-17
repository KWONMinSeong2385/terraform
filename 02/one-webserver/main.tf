provider "aws" {
  region = var.myregion
}

# ec2 instance 생성
# + webserver 구성 => user_data
# + security group 생성

resource "aws_instance" "example" {
  ami                         = var.amiUbuntu2204
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.allow_8080.id]
  user_data_replace_on_change = var.myUserdataChanged
  tags                        = var.myWebserverTags

  user_data = <<EOF
#!/bin/bash
echo "Hello, World" > index.html
nohup busybox httpd -f -p 8080 &
EOF

}

#
# securt group
#

resource "aws_security_group" "allow_8080" {
  name        = "allow_8080"
  description = "Allow TLS inbound traffic and all outbound traffic"
  tags = var.mySgTags
}

resource "aws_vpc_security_group_ingress_rule" "allow_8080_ipv4" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.myHttp
  to_port           = var.myHttp
  ip_protocol       = "tcp"  
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
