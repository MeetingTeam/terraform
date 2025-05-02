# Region
variable "region" {
  description = "AWS Region để triển khai resources"
  type        = string
  default     = "ap-southeast-1"
}

# Environment
variable "env" {
  description = "Môi trường triển khai"
  type        = string
  default     = "dev"
}

# Cluster name
variable "cluster_name" {
  description = "Tên của cluster"
  type        = string
  default     = "doan-cluster"
}

# VPC CIDR
variable "vpc_cidr" {
  description = "CIDR block của VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Kubernetes version
variable "kubernetes_version" {
  description = "Phiên bản Kubernetes"
  type        = string
  default     = "1.28"
}

# Key name for SSH access
variable "key_name" {
  description = "Tên của EC2 key pair để SSH vào worker nodes"
  type        = string
  default     = ""  # Để trống nếu không cần SSH access
}

# Tags
variable "tags" {
  description = "Các tags chung cho tất cả resources"
  type        = map(string)
  default     = {
    Project     = "DoanProject"
    Owner       = "DevOps"
    ManagedBy   = "Terraform"
  }
}




variable "private_app_subnet_cidrs" {
  description = "CIDR blocks cho private application subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}



# Availability Zones
variable "availability_zones" {
  description = "Availability zones sử dụng cho subnets"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

# EKS Worker Nodes
variable "instance_types" {
  description = "EC2 instance types cho EKS worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "disk_size" {
  description = "Kích thước ổ đĩa (GB) cho worker nodes"
  type        = number
  default     = 30
}

variable "desired_capacity" {
  description = "Số lượng worker nodes mong muốn"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Số lượng worker nodes tối thiểu"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Số lượng worker nodes tối đa"
  type        = number
  default     = 4
}







