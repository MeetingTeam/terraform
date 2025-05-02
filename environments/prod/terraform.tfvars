region            = "ap-southeast-1"
env               = "prod"
cluster_name      = "doan-cluster"
vpc_cidr          = "10.1.0.0/16"
kubernetes_version = "1.28"
key_name          = "volunteer-work-keypair"  # Thay bằng tên key pair thực tế nếu cần SSH access
mysql_password       = "Admin!123456" # Nên sử dụng AWS Secrets Manager trong môi trường thực tế
docdb_password       = "Admin!123456" # Nên sử dụng AWS Secrets Manager trong môi trường thực tế
create_mysql         = true
create_documentdb    = true
mysql_instance_class = "db.t3.medium"
docdb_instance_class = "db.t3.medium"
# Subnet configurations
public_subnet_cidrs     = ["10.1.1.0/24", "10.1.2.0/24"]
private_app_subnet_cidrs = ["10.1.3.0/24", "10.1.4.0/24"]
private_data_subnet_cidrs = ["10.1.5.0/24", "10.1.6.0/24"]