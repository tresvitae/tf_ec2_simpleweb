### commands

Configuration includes a virtual private cloud (VPC) with a 2 public subnets and a 2 private subnets. Scenario of a public-facing web application, while maintaining back-end servers that aren't publicly accessible. A common example is a multi-tier website, with the web servers in a public subnet and the database servers in a private subnet. You can set up security and routing so that the web servers can communicate with the database servers. 

Traffic on public subnets, where facing-app Nginx is installed, passes through the Application Load Balancer.

sh ```terraform init
terraform validate
terraform plan -out m3.tfplan
terraform apply "m3.tfplan"
terraform destroy
```
