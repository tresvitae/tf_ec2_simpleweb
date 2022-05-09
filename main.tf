# PROVIDERS
provider "aws" {
  profile                  = var.aws_worker_profile
  region                   = var.region
  shared_credentials_files = [var.shared_credentials_files]
}

# DATA
data "aws_ami" "aws_linux" {
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

# LOCALS
locals {
  env_name = terraform.workspace
  common_tags = {
    EnvironmentName = local.env_name
    EnvironmentType = var.environment_type
  }
}

# RESOURCES
resource "aws_security_group" "nginx_sg" {
  name        = "web_nginx_sg"
  description = "Allow ports to website"
  vpc_id      =  module.vpc.web_vpc_id
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

  tags = merge(local.common_tags, { Name = "nginx_sg--${local.env_name}" })
}

resource "aws_instance" "nginx" {
  count                  = var.instance_count[terraform.workspace]
  ami                    = data.aws_ami.aws_linux.id
  instance_type          = var.instance_type[terraform.workspace]
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.nginx_sg.id]
  subnet_id              = module.vpc.subnet_for_nginx_instance

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_pair_path)
  }

  provisioner "file" {
    content     = <<EOF
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
  tags = merge(local.common_tags, { Name = "nginx--${local.env_name}" })
}

module "rds" {
  source           = "./modules/rds"
  engine_name      = var.engine_name
  engine_version   = var.engine_version
  db_storage_size  = var.db_storage_size[terraform.workspace]
  db_instance_type = var.db_instance_type[terraform.workspace]
  subnets          = module.vpc.vpc_all_priv_subnets_id # for DB Subnet
  environment_vpc  = module.vpc.web_vpc_id # for SG
  sg_access_to_db  = [aws_security_group.nginx_sg.id]
  common_tags      = local.common_tags
  env_name         = local.env_name
}

module "elb" {
  source      = "./modules/elb"
  elb_name    = "elb-nginx--${lower(local.env_name)}"
  subnets     = module.vpc.vpc_all_pub_subnets_id
  instances   = aws_instance.nginx[*].id
  vpc         = module.vpc.web_vpc_id
  common_tags = local.common_tags
  env_name    = local.env_name
}

module "vpc" {
  source = "./modules/vpc"
    common_tags = local.common_tags
  env_name    = local.env_name

  network_address = var.network_address
  subnet_count = var.subnet_count
}