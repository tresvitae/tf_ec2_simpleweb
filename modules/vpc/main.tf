data "aws_availability_zones" "available" {}

resource "aws_vpc" "web_vpc" {
  cidr_block           = var.network_address[terraform.workspace]
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, { Name = "vpc--${var.env_name}" })
}

resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "rds_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.privsub[0].id # Will select first private subnet
  depends_on    = [aws_internet_gateway.igw]

  tags = merge(var.common_tags, { Name = "rds_nat--${var.env_name}" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.web_vpc.id

  tags = merge(var.common_tags, { Name = "igw--${var.env_name}" })
}

resource "aws_subnet" "pubsub" {
  count                   = var.subnet_count[terraform.workspace]
  cidr_block              = cidrsubnet(var.network_address[terraform.workspace], 8, count.index)
  vpc_id                  = aws_vpc.web_vpc.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.common_tags, { Name = "${var.env_name}--pubsub${count.index + 1}" })
}

resource "aws_subnet" "privsub" {
  count                   = var.subnet_count[terraform.workspace]
  cidr_block              = cidrsubnet(var.network_address[terraform.workspace], 8, count.index + 10)
  vpc_id                  = aws_vpc.web_vpc.id
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.common_tags, { Name = "${var.env_name}--privsub${count.index + 10}" })
}

# # Routing
resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.web_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.common_tags, { Name = "rtb_pubic--${var.env_name}" })
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

  tags = merge(var.common_tags, { Name = "rtb_private--${var.env_name}" })
}

resource "aws_route_table_association" "rtb-privsub" {
  count          = var.subnet_count[terraform.workspace]
  subnet_id      = aws_subnet.privsub[count.index].id
  route_table_id = aws_route_table.rtb_private.id
}