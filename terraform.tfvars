key_pair_name = "softserve"

private_key_pair_path = "C:\\Users\\pfuta\\softserve.pem"

network_address = {
    Development = "10.10.0.0/16"
    UAT = "10.11.0.0/16"
    Production = "10.12.0.0/16"
}
instance_type = {
  Development = "t2.micro"
  UAT = "t2.small"
  Production = "t2.medium"
}

# Number of private and public subnets 
subnet_count = {
  Development = 2
  UAT = 2
  Production = 3
}

instance_count = {
  Development = 2
  UAT = 4
  Production = 6
}
/*
db_instance_type = {
  Development = "db.t2.micro"
  UAT = "db.t2.small"
  Production = "db.t2.medium"
}

db_storage_size = {
  Development = 10
  UAT = 20
  Production = 50
}
*/