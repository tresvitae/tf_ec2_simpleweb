# VARIABLES
variable "private_key_pair_path" {}
variable "key_pair_name" {} # key name cannot be created in TF
variable "region" {
    default = "eu-west-1"
}

# # Environment
variable "environment_type" {
    default = "Development"
}
variable "instance_count" {
    type = map(number)
}
variable "instance_type" {
    type = map(string)
}
/*
variable "db_instance_type" {
    type = map(string)
}
variable "db_storage_size" {
    type = map(number)
}
*/
# # Netowrking
variable "network_address" {
    type = map(string)
}
variable "subnet_count" {
    type = map(number)
}

# LOCALS
locals {
    env_name = terraform.workspace
    common_tags = {
        EnvironmentName = local.env_name
        EnvironmentType = var.environment_type
    }
}