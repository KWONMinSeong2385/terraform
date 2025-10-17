variable "server_http_port" {
  default = 80
}

variable "server_https_port" {
  default = 443
}

variable "instance_type" {
  default = "t3.micro"
}

variable "instance_min_size" {
  default = 2
}

variable "instance_max_size" {
  default = 10
}
