variable "vpc_id" {
  description = "ID của VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block của VPC"
  type        = string
}

variable "env" {
  description = "Môi trường triển khai"
  type        = string
}

variable "cluster_name" {
  description = "Tên của cluster"
  type        = string
}

variable "region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "allow_ssh_from_ips" {
  description = "List các IP được phép SSH vào instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Có thể xóa biến này vì không cần nữa
# variable "enable_db_access" {
#   description = "Có cho phép truy cập database từ bên ngoài không"
#   type        = bool
#   default     = false
# }

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}