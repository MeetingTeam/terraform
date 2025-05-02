variable "cluster_name" {
  description = "Tên của EKS cluster"
  type        = string
}

variable "env" {
  description = "Môi trường triển khai (dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID của VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs của các private subnets cho mount targets"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID của security group cho EFS"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "ap-southeast-1"
}

variable "tags" {
  description = "Tags cho resources"
  type        = map(string)
  default     = {}
}