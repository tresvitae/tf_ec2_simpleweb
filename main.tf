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
data "aws_availability_zones" "available" {}

# LOCALS
locals {
  env_name = terraform.workspace
  common_tags = {
    EnvironmentName = local.env_name
    EnvironmentType = var.environment_type
  }
}

# RESOURCES
# # Networking
resource "aws_vpc" "web_vpc" {
  cidr_block           = var.network_address[terraform.workspace]
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, { Name = "vpc--${local.env_name}" })
}

resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "rds_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.privsub[0].id # Will select first private subnet
  depends_on    = [aws_internet_gateway.igw]

  tags = merge(local.common_tags, { Name = "rds_nat--${local.env_name}" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.web_vpc.id

  tags = merge(local.common_tags, { Name = "igw--${local.env_name}" })
}

resource "aws_subnet" "pubsub" {
  count                   = var.subnet_count[terraform.workspace]
  cidr_block              = cidrsubnet(var.network_address[terraform.workspace], 8, count.index)
  vpc_id                  = aws_vpc.web_vpc.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, { Name = "${local.env_name}--pubsub${count.index + 1}" })
}

resource "aws_subnet" "privsub" {
  count                   = var.subnet_count[terraform.workspace]
  cidr_block              = cidrsubnet(var.network_address[terraform.workspace], 8, count.index + 10)
  vpc_id                  = aws_vpc.web_vpc.id
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, { Name = "${local.env_name}--privsub${count.index + 10}" })
}

# # Routing
resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.web_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, { Name = "rtb_pubic--${local.env_name}" })
}

resource "aws_route_table_association" "rtb_pubsub" {
  count          = var.subnet_count[terraform.workspace]
  subnet_id      = aws_subnet.pubsub[count.index].id
  route_table_id = aws_route_table.rtb_public.id
}

resource "aws_route_table" "rtb_private" {
  vpc_id = aws_vpc.web_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.rds_nat.id
  }

  tags = merge(local.common_tags, { Name = "rtb_private--${local.env_name}" })
}

resource "aws_route_table_association" "rtb-privsub" {
  count          = var.subnet_count[terraform.workspace]
  subnet_id      = aws_subnet.privsub[count.index].id
  route_table_id = aws_route_table.rtb_private.id
}

resource "aws_security_group" "nginx_sg" {
  name        = "web_nginx_sg"
  description = "Allow ports to website"
  vpc_id      = aws_vpc.web_vpc.id
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
  subnet_id              = aws_subnet.pubsub[count.index % var.subnet_count[terraform.workspace]].id

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
  subnets          = aws_subnet.privsub[*].id # for DB Subnet
  environment_vpc  = aws_vpc.web_vpc.id       # for SG
  sg_access_to_db  = aws_security_group.nginx_sg.id
  common_tags      = local.common_tags
  env_name         = local.env_name
}

module "elb" {
  source      = "./modules/elb"
  elb_name    = "elb-nginx--${lower(local.env_name)}"
  subnets     = aws_subnet.pubsub[*].id
  instances   = aws_instance.nginx[*].id
  vpc         = aws_vpc.web_vpc.id
  common_tags = local.common_tags
  env_name    = local.env_name
}