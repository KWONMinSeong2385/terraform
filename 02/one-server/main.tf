provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "example" {
  ami           = "ami-077b630ef539aa0b5"
  instance_type = "t3.micro"
  tags = {
    Name = "terraform-example"
  }
}