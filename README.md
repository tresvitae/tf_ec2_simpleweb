Configuration includes a VPC with a public subnets and a private subnets. Scenario of a public-facing web application, while maintaining back-end servers that aren't publicly accessible. A common example is a multi-tier website, with the web servers in a public subnet and the database servers in a private subnet. You can set up security and routing so that the web servers can communicate with the database servers. 

Traffic on public subnets, where facing-app Nginx is installed, passes through the Application Load Balancer.



```sh
terraform init
terraform validate
terraform plan -out build.tfplan
terraform apply build.tfplan
terraform plan -destroy -out destroy.tfplan
terraform destroy
```