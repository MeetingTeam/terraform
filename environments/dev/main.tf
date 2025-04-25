terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}
provider "aws" {
  region = var.region
}

# Thêm định nghĩa locals này ở đầu file, sau các provider
locals {
  cluster_name = var.cluster_name
  env          = var.env
  tags         = var.tags
}

module "network" {
  source = "../../modules/network"
  
  env                     = var.env
  type                    = "eks"
  cluster_name            = var.cluster_name
  vpc_cidr                = var.vpc_cidr
  region                  = var.region
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  availability_zones      = var.availability_zones
  tags                    = var.tags
}

##########################################
# Security Groups Module
##########################################
module "security" {
  source = "../../modules/security-groups"
  
  vpc_id          = module.network.vpc_id
  vpc_cidr        = var.vpc_cidr
  env             = var.env
  cluster_name    = var.cluster_name
  region          = var.region
#   enable_db_access = true  # Cho phép truy cập trực tiếp tới database trong môi trường dev
  tags            = var.tags
}

##########################################
# IAM Module
##########################################
module "iam" {
  source = "../../modules/iam"
  
  cluster_name    = var.cluster_name
  env             = var.env
  region          = var.region
  tags            = var.tags
}

##########################################
# Keypair Module (Nếu cần SSH access)
##########################################
module "keypair" {
  source    = "../../modules/keypair"
  count     = var.key_name != "" ? 1 : 0
  key_name  = var.key_name
}

##########################################
# EKS Cluster Module
##########################################
module "eks" {
  source = "../../modules/eks"
  
  cluster_name      = var.cluster_name
  env               = var.env
  region            = var.region
  kubernetes_version = var.kubernetes_version
  
  # Network
  vpc_id            = module.network.vpc_id
  private_subnet_ids = module.network.private_app_subnet_ids
  
  # Security
  cluster_sg_id    = module.security.eks_cluster_sg_id
  node_sg_id       = module.security.eks_nodes_sg_id
  
  # IAM
  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_node_role_arn
  
  # Sử dụng các biến mới
  instance_types   = var.instance_types
  disk_size        = var.disk_size
  desired_capacity = var.desired_capacity
  min_capacity     = var.min_capacity
  max_capacity     = var.max_capacity
  


  
  # SSH access
  key_name         = var.key_name
  
  tags             = var.tags
  
  depends_on = [
    module.network,
    module.security,
    module.iam
  ]
}

module "database" {
  source = "../../modules/database"

  cluster_name           = local.cluster_name
  env                    = local.env
  private_data_subnet_ids = [
    module.network.private_data_subnet1_id,
    module.network.private_data_subnet2_id
  ]
  
  # Kích hoạt tạo database theo nhu cầu
  create_mysql           = true
  create_documentdb      = true
  
  # MySQL config
  rds_sg_id              = module.security.rds_sg_id
  mysql_db_name          = "appdb"
  mysql_username         = "dbadmin"
  mysql_password         = var.mysql_password
  mysql_instance_class   = "db.t3.medium"
  mysql_multi_az         = true
  mysql_allocated_storage = 20
  
  # DocumentDB config
  docdb_sg_id            = module.security.docdb_sg_id
  docdb_username         = "dbadmin"
  docdb_password         = var.docdb_password
  docdb_instance_class   = "db.t3.medium"
  docdb_instance_count   = 2
  docdb_deletion_protection = false
  
  tags                   = local.tags
}