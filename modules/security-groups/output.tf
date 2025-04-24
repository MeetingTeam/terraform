output "eks_cluster_sg_id" {
  description = "ID của Security Group cho EKS cluster"
  value       = aws_security_group.eks_cluster_sg.id
}

output "eks_nodes_sg_id" {
  description = "ID của Security Group cho EKS worker nodes"
  value       = aws_security_group.eks_nodes_sg.id
}