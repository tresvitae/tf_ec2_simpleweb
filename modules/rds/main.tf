# Database Module
/*
resource "aws_db_instance" "rds" {
  db identifier?
  allocated_storage      = var.db_storage_size
  engine                 = "mysql"
  engine_version         = "8.0.23"
  instance_class         = var.db_instance_type
  multi_az               = "true"
  username               = var.rds_username
  password               = var.rds_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.id
  vpc_security_group_ids = [var.nginx-sg]
  skip_final_snapshot    = true

  tags = merge(local.common_tags, { Name = "rds--${local.env_name}" })
}
*/
resource "aws_db_subnet_group" "db_subnet" {
  name       = "${lower(terraform.workspace)}-rds-subnet-group"
  subnet_ids = var.subnets
}
