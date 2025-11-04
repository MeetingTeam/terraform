terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
   backend "s3" {
  bucket         = "nt548-terraform-state-dev"
  key            = "terraform.tfstate"
  region         = "ap-southeast-1"
  dynamodb_table = "nt548-terraform-lock-dev"
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



module "jenkins_efs" {
  source = "../../modules/efs"
  
  cluster_name       = var.cluster_name
  env                = var.env
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_app_subnet_ids
  security_group_id  = module.security.efs_sg_id
  region             = var.region
  
  tags = var.tags
  
  depends_on = [module.eks]
}