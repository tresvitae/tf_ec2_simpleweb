/*
# Database Module
resource "aws_db_instance" "rds" {
  allocated_storage      = var.db_storage_size
  max_allocated_storage  = var.db_storge_size[terraform.workspace] * 2
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = var.db_instance_type
 # multi_az               = local.rds_multi_az
  username               = var.rds_username
  password               = var.rds_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.id
 # vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true

  tags = merge(local.common_tags, { Name = "rds--${local.env_name}" })
}
*/

resource "aws_db_subnet_group" "db_subnet" {
  name       = "${lower(terraform.workspace)}-rds-subnet-group"
  subnet_ids = var.subnets
}
