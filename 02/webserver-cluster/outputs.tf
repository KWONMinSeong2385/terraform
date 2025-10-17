output "alb_dns_name" {
    value = aws_lb.myALB.dns_name
}

output "alb_url" {
    value = "http://${aws_lb.myALB.dns_name}:${var.server_http_port}"
}