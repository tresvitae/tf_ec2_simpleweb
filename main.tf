#VARIABLES
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_pair_path" {}
variable "key_pair_name" {} # key name cannot be created in TF
variable "region" {
    default = "eu-west-1"
}
# # Netowrking
variable "network_address" {
    default = "10.10.0.0/16"  
}
variable "pubsub1_address" {
    default = "10.10.100.0/24"
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
      values = ["amzn-ami-hvm*"]
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

data "aws_availability_zones" "available" {}

# RESOURCES
# # Networking
resource "aws_vpc" "web_vpc"{
    cidr_block           = var.network_address
    enable_dns_hostnames = "true"
}
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.web_vpc.id
}
resource "aws_subnet" "pubsub1" {
    cidr_block              = var.pubsub1_address
    vpc_id                  = aws_vpc.web_vpc.id
    map_public_ip_on_launch = "true"
    availability_zone       = data.aws_availability_zones.available.names[0]
}
# # Routing
resource "aws_route_table" "rtb" {
    vpc_id = aws_vpc.web_vpc.id
}
resource "aws_route_table_association" "rtb-pubsub1" {
    subnet_id      = aws_subnet.pubsub1.id
    route_table_id = aws_route_table.rtb.id
}
# # Security Groups
resource "aws_security_group" "nginx-sg" {
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
# # Instances
resource "aws_instance" "nginx1" {
    ami                    = data.aws_ami.aws-linux.id
    instance_type          = "t2.micro"
    key_name               = var.key_pair_name
    vpc_security_group_ids = [aws_security_group.nginx-sg.id]
    subnet_id              = aws_subnet.pubsub1.id

    connection {
        type        = "ssh"
        host        = self.public_ip
        user        = "ec2-user"
        private_key = file(var.private_key_pair_path)
    }

    provisioner "remote-exec" {
        inline = [
            "sudo yum install nginx -y",
            "sudo service nginx start",
            "echo '<html><head><title>Public Subnet 1</title></head><body style=\"background-color:#BA55D3\"><p style=\"text-align: justify;\"><span style=\"color:#FFFFFF;\"><span style=\"font-size:56px;\">PubSub1</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html"
        ]
    }
}

# OUTPUT
output "aws_instance_public_dns" {
    value = aws_instance.nginx1.public_dns
}