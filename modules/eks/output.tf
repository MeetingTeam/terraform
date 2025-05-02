output "cluster_id" {
  description = "ID của EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "ARN của EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint cho EKS control plane API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "Certificate authority data cho cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID được gắn vào cluster control plane"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "node_group_id" {
  description = "ID của EKS node group"
  value       = aws_eks_node_group.main.id
}

output "node_group_arn" {
  description = "ARN của EKS node group"
  value       = aws_eks_node_group.main.arn
}

output "node_group_resources" {
  description = "Thông tin về resources được tạo bởi EKS node group"
  value       = aws_eks_node_group.main.resources
}

output "kubeconfig_command" {
  description = "Lệnh để cập nhật kubeconfig để kết nối đến cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.main.name}"
}

