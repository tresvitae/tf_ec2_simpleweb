variable "elb_name" {}

variable "subnets" {}

variable "instances" {}

variable "elb_sg_name" {
  default = "elb_sg"
}

variable "vpc" {}

variable "common_tags" {}

variable "env_name" {}