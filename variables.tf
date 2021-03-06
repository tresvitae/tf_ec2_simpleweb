variable "private_key_pair_path" {}

variable "key_pair_name" {} # key name cannot be created in TF

variable "region" {
  default = "eu-west-1"
}

variable "aws_worker_profile" {
  default = "terraform"
}

variable "shared_credentials_files" {
  default = "~/.aws/credentials"
}

variable "environment_type" {
  default = "Development"
}

variable "instance_count" {
  type = map(number)
}

variable "instance_type" {
  type = map(string)
}

# # Database
variable "db_instance_type" {
  type = map(string)
}

variable "db_storage_size" {
  type = map(number)
}

variable "engine_name" {
  type = string
}

variable "engine_version" {
  type = string
}

# # Netowrking
variable "network_address" {
  type = map(string)
}

variable "subnet_count" {
  type = map(number)
}

