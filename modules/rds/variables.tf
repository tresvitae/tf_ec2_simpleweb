variable "rds_username" {
  default     = "admin"
  type        = string
}
variable "rds_password" {
  default     = "admin123"
  type        = string
}
variable "subnets" {}
variable "environment_type" {
    default = "Development"
}
variable "db_instance_type" {}
variable "db_storage_size" {}
variable "engine_name" {}
variable "engine_version" {}
variable "environment_vpc" {}
variable "sg_access_to_db" {}
# LOCALS
locals {
    env_name = terraform.workspace
    common_tags = {
        EnvironmentName = local.env_name
        EnvironmentType = var.environment_type
    }
}