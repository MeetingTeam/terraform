variable "cluster_name" {
  description = "Tên của EKS cluster"
  type        = string
}

variable "env" {
  description = "Môi trường triển khai (dev, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS Region để triển khai resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "kubernetes_version" {
  description = "Phiên bản Kubernetes sử dụng cho EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "ID của VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List các ID của private subnet dùng cho EKS nodes"
  type        = list(string)
}

variable "cluster_sg_id" {
  description = "ID của security group cho EKS control plane"
  type        = string
}

variable "node_sg_id" {
  description = "ID của security group cho EKS worker nodes"
  type        = string
}

variable "cluster_role_arn" {
  description = "ARN của IAM role cho EKS cluster"
  type        = string
}

variable "node_role_arn" {
  description = "ARN của IAM role cho EKS nodes"
  type        = string
}

variable "instance_types" {
  description = "List các loại EC2 instance sử dụng cho worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "disk_size" {
  description = "Kích thước ổ đĩa (GB) cho worker nodes"
  type        = number
  default     = 20
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

variable "key_name" {
  description = "Tên của EC2 key pair để truy cập worker nodes (để trống nếu không sử dụng)"
  type        = string
  default     = ""
}



variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}


variable "run_post_install_script" {
  description = "Có chạy script cài đặt sau khi triển khai EKS không"
  type        = bool
  default     = true
}

variable "force_update_post_install" {
  description = "Force chạy lại post-installation script"
  type        = bool
  default     = false
}
