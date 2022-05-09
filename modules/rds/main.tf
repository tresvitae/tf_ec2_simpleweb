# Database Module
resource "aws_db_instance" "rds" {
  identifier             = "rds-mysql-${lower(var.env_name)}"
  allocated_storage      = var.db_storage_size
  engine                 = var.engine_name
  engine_version         = var.engine_version
  instance_class         = var.db_instance_type
  multi_az               = true
  username               = var.rds_username
  password               = var.rds_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true

  tags = merge(var.common_tags, { Name = "rds-mysql--${var.env_name}" })
}
resource "aws_db_subnet_group" "db_subnet" {
  name       = "${lower(terraform.workspace)}-rds-subnet-group"
  subnet_ids = var.subnets
}

resource "aws_security_group" "db_sg" {
  name =  "rds_sg"
  description = "SG that allow incoming traffic to the RDS instance"
  vpc_id = var.environment_vpc
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.sg_access_to_db]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.common_tags, { Name = "db-sg--${var.env_name}" })
}