output "cluster_id" {
  description = "ID của EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint của EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
  description = "Lệnh để cập nhật kubeconfig"
  value       = module.eks.kubeconfig_command
}

output "vpc_id" {
  description = "ID của VPC"
  value       = module.network.vpc_id
}

output "private_app_subnet_ids" {
  description = "ID các private subnet cho application"
  value       = module.network.private_app_subnet_ids
}

output "public_subnet_ids" {
  description = "ID các public subnet"
  value       = module.network.public_subnet_ids
}