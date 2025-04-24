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
  description = "AWS Region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "oidc_provider_enabled" {
  description = "Có tạo OIDC provider cho EKS không (để hỗ trợ IRSA)"
  type        = bool
  default     = true
}

variable "create_alb_controller_role" {
  description = "Có tạo IAM role cho AWS Load Balancer Controller không"
  type        = bool
  default     = true
}

variable "create_ebs_csi_role" {
  description = "Có tạo IAM role cho EBS CSI driver không"
  type        = bool
  default     = true
}