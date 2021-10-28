/*
variable "rds_username" {
  default     = "admin"
  type        = string
}
variable "rds_password" {
  default     = "admin123"
  type        = string
}
*/
variable "subnets" {
}
variable "environment_type" {
    default = "Development"
}
/*
variable "nginx-sg" {
}

variable "db_instance_type" {
}
variable "db_storage_size" {
}
*/
# LOCALS
locals {
    env_name = terraform.workspace
    common_tags = {
        EnvironmentName = local.env_name
        EnvironmentType = var.environment_type
    }
}