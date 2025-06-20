variable "environment" {
  description = "Môi trường triển khai (dev hoặc prod)"
  type        = string
}

variable "argo_cd_repository" {
  description = "Repository của Argo CD chart"
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
}



variable "argo_cd_namespace" {
  description = "Namespace để triển khai Argo CD"
  type        = string
  default     = "argo"
}