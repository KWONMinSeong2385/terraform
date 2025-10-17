#
# output Variable 정의
#
output "mywebPublicIP" {
  description = "My webserver"
  value       = aws_instance.example.public_ip
}

# value 값이 중요 
# 해당값은 [File]terraform.tfstate 에 존재
# tf state list로 출력
# tf state show aws_instance.example(=EC2name)
# -> public IP, public DNS ...
# -> ex) aws_instance.example.public_dns

output "mywebPublicDNS"{
    description = "My webserver Public DNS"
    value = aws_instance.example.public_dns
}

# tf output
# tf output mywebPublicDNS
# tf output -rwa mywebPublicDNS
# curl $(tf output mywebPublicDNS):8080


