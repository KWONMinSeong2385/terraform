#
# input Variable 정의
#

variable "myregion" {
  description = "AWS My Region"
  type        = string
  default     = "us-east-2"
}

variable "amiUbuntu2204" {
  description = "AWS My AMI - Ubuntu 24.04 LTS(x86_64)"
  type        = string
  default     = "ami-0cfde0ea8edd312d4"
}

variable "myInstanceType" {
  description = "My Ubuntu Instance Type"
  type        = string
  default     = "t3.micro"
}

variable "myUserdataChanged" {
  description = "User Data Replace on Change"
  type        = bool
  default     = true
}

variable "myWebserverTags" {
  description = "My Webserver Tags"
  type        = map(any)

  default = {
    Name = "mywebserver"
  }
}

variable "mySgTags"{
  description = "My Security Group Tags"
  type = map(string)

  default = {
    Name = "allow_8080"
  }
}

variable "myHttp" {
  description = "My HTTP Port"
  type = number
  default = 8080
}


