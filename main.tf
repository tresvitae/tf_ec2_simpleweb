#VARIABLES
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {} # key name cannot be created in TF
variable "region" {
  default = "eu-west-1"
}

# PROVIDERS
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

# DATA
data "aws_ami" "aws-linux" {
    most_recent = true
    owners      = ["amazon"]

    filter {
      name   = "name"
      values = ["amzn-ami-hvm"]
    }

    filter {
      name   = "root-device-type"
      values = ["ebs"]
    }

    filter {
      name   = "virtualization-type"
      values = ["hvm"]
    }
}

# RESOURCES
resource "aws_vpc" "web_vpc"{

}

resource "aws_security_group" "allow_ssh" {
    name = "web_nginx"
    description = "Allow ports to website"
    vpc_id = aws_vpc.web_vpc.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "nginx" {
    ami =
    instance_type = "t2.micro"
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.allow_ssh.id]

    connection {
      type = "ssh"
      host = self.public_ip
      user = "ec2-user"
      private_key = file(var.private_key_path)
    

    }
  
}


# OUTPUT

output "aws_instance_public_dns" {
    value = aws_instance.nginx.public_dns
  
}