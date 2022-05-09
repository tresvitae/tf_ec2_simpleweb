output "vpc_all_priv_subnets_id" {
  value = aws_subnet.privsub[*].id
}
output "vpc_all_pub_subnets_id" {
  value = aws_subnet.pubsub[*].id
}
output "web_vpc_id" {
  value = aws_vpc.web_vpc.id
}

output "subnet_for_nginx_instance" {
  value = "aws_subnet.pubsub[count.index % var.subnet_count[terraform.workspace]].id"
}