####################################
# 구성목표 : ALB + TG(ASG)
####################################
# 구성순서
# 1. Launch Template
#  ㄴ SG
#  ㄴ LT
# 2. ASG
# 3. TG
#  ㄴ SG
#  ㄴ TG
# 4. ALB
#  ㄴ ALB Listener
#  ㄴ ALB rule
####################################


####################################
# 1. Launch Template > Default VPC
####################################
data "aws_vpc" "default" {
  default = true
}


####################################
# 1 Launch Template > SG
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
####################################
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow WEB inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "allow_web"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_80" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = var.server_http_port
  to_port           = var.server_http_port
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_443" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = var.server_https_port
  to_port           = var.server_https_port
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

####################################
# 1. Launch Template > Amazon Linux 2023 AMI
# LT 구성전 사용할 AMI 정의
####################################
data "aws_ami" "amz2023ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"]
}

####################################
# 1. Launch Template > LT
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template
####################################

resource "aws_launch_template" "myLT" {
  name = "myLT"

  image_id = data.aws_ami.amz2023ami.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.allow_web.id]
  # https://developer.hashicorp.com/terraform/language/functions/filebase64
  user_data = filebase64("./LT_user_data.sh")

  # lifecycle은 user_data부분에 변경이 생기면 다시 동작하여 설정 
  lifecycle {
    create_before_destroy = true
  }
}


####################################
# 2. ASG > Subnet
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
####################################

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


####################################
# 2. ASG
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#argument-reference
####################################
resource "aws_autoscaling_group" "myASG" {
  vpc_zone_identifier = data.aws_subnets.default_subnets.ids
  desired_capacity   = 2
  min_size           = var.instance_min_size
  max_size           = var.instance_max_size

  # [중요] 필수 설정값(타겟설정이후)
  target_group_arns = [aws_lb_target_group.myTG.arn]
  depends_on = [aws_lb_target_group.myTG]

  launch_template {
    id      = aws_launch_template.myLT.id
  }
}


####################################
# 3. TG > SG
# 위에서 만든 SG 그대로 사용
####################################


####################################
# 3. TG
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
####################################
# Default Health 사용
resource "aws_lb_target_group" "myTG" {
  name        = "myALB-TG"
  target_type = "instance"
  port        = var.server_http_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


####################################
# 4. ALB
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
####################################
# SG는 기존 생성된거 사용
resource "aws_lb" "myALB" {
  name               = "myALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = data.aws_subnets.default_subnets.ids

  #enable_deletion_protection = true
}


####################################
# 4. ALB > ALB Listener
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
####################################
resource "aws_lb_listener" "myALB_listener" {
  load_balancer_arn = aws_lb.myALB.arn
  port              = var.server_http_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: Page Not Found"
      status_code  = "404"
    }
  }
}


####################################
# 4. ALB > ALB Listener rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule
####################################
resource "aws_lb_listener_rule" "myALB_listener_rule" {
  listener_arn = aws_lb_listener.myALB_listener.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myTG.arn
  }
}
