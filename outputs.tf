output "aws_instance_public_dns" {
  value = module.elb.dns_name
}