#VARIABLES
variable "private_key_pair_path" {}
variable "key_pair_name" {} # key name cannot be created in TF
variable "region" {
    default = "eu-west-1"
}
# # Environment
variable "environment_name" {
    default = "Simple Web App"
}
variable "environment_type" {
    default = "dev"
}
variable "instance_count" {
  default = 2
}
variable "subnet_count" {
  default = 2
}
# # Netowrking
variable "network_address" {
    default = "10.10.0.0/16"  
}

# PROVIDERS
provider "aws" {
    profile = "default"
    region     = var.region
}

# LOCALS
locals {
    common_tags = {
        EnvironmentName = var.environment_name
        EnvironmentType = var.environment_type
    }
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
resource "aws_vpc" "web-vpc"{
    cidr_block           = var.network_address
    enable_dns_hostnames = "true"

    tags = merge(local.common_tags, { Name = "${var.environment_name}--vpc" })
}
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.web-vpc.id

    tags = merge(local.common_tags, { Name = "${var.environment_name}--igw" })
}
resource "aws_subnet" "pubsub" {
    count                   = var.subnet_count
    cidr_block              = cidrsubnet(var.network_address, 8, count.index)
    vpc_id                  = aws_vpc.web-vpc.id
    map_public_ip_on_launch = "true"
    availability_zone       = data.aws_availability_zones.available.names[count.index]

    tags = merge(local.common_tags, { Name = "${var.environment_name}--pubsub${count.index + 1}" })
}
# # Routing
resource "aws_route_table" "rtb-public" {
    vpc_id = aws_vpc.web-vpc.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = merge(local.common_tags, { Name = "${var.environment_name}--rtb" })
}
resource "aws_route_table_association" "rtb-pubsub" {
    count          = var.subnet_count
    subnet_id      = aws_subnet.pubsub[count.index].id
    route_table_id = aws_route_table.rtb-public.id
}
# # Security Groups
resource "aws_security_group" "elb-sg" {
    name   = "nginx_elb_sg"
    vpc_id = aws_vpc.web-vpc.id
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
    tags = merge(local.common_tags, { Name = "${var.environment_name}--elb-sg" })
}
resource "aws_security_group" "nginx-sg" {
    name = "web_nginx_sg"
    description = "Allow ports to website"
    vpc_id = aws_vpc.web-vpc.id

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
    tags = merge(local.common_tags, { Name = "${var.environment_name}--nginx-sg" })
}
# # Load Balancer
resource "aws_elb" "web-elb" {
    name            = "nginxELB"
    subnets         = aws_subnet.pubsub[*].id
    security_groups = [aws_security_group.elb-sg.id]
    instances       = aws_instance.nginx[*].id
    listener {
        instance_port     = 80
        instance_protocol = "http"
        lb_port           = 80
        lb_protocol       = "http"
    }
    tags = merge(local.common_tags, { Name = "${var.environment_name}--web-elb" })
}
# # Instances
resource "aws_instance" "nginx" {
    count                  = var.instance_count
    ami                    = data.aws_ami.aws-linux.id
    instance_type          = "t2.micro"
    key_name               = var.key_pair_name
    vpc_security_group_ids = [aws_security_group.nginx-sg.id]
    subnet_id              = aws_subnet.pubsub[count.index % var.subnet_count].id

    connection {
        type        = "ssh"
        host        = self.public_ip
        user        = "ec2-user"
        private_key = file(var.private_key_pair_path)
    }

    provisioner "file" {
        content = <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Simple Web App</title>
</head>
<body style=\"background-color:#BA55D3\">
<p style=\"text-align: justify;\"><span style=\"color:#FFFFFF;\">
<span style=\"font-size:56px;\">
    <div><object data="websiteOutput.txt"></object></div>
</span>
</span>
</p>
</body>
</html>
    }
    EOF
        destination = "/home/ec2-user/index.html"
   }

    provisioner "remote-exec" {
        inline = [
            "sudo yum install nginx -y",
            "sudo service nginx start",
            "sudo curl http://169.254.169.254/latest/meta-data/instance-id -o /usr/share/nginx/html/websiteOutput.txt",
            "sudo rm /usr/share/nginx/html/index.html",
            "sudo cp /home/ec2-user/index.html /usr/share/nginx/html/index.html"
        ]
    }
    tags = merge(local.common_tags, { Name = "${var.environment_name}--nginx" })
}

#NATGateway
#RDS


# OUTPUT
output "aws_instance_public_dns" {
    value = aws_elb.web-elb.dns_name
}
            # "echo '<html><head><title>Public Subnet</title></head><body style=\"background-color:#BA55D3\"><p style=\"text-align: justify;\"><span style=\"color:#FFFFFF;\"><span style=\"font-size:56px;\">PubSub1</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html"
#            "echo '<!DOCTYPE html><html><head><title>Public Subnet</title></head><body style=\"background-color:#BA55D3\"><p style=\"text-align: justify;\"><span style=\"color:#FFFFFF;\"><span style=\"font-size:56px;\">PubSub<script> function getURL() { alert(window.location.href);}</script></span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html"
