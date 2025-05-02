output "eks_cluster_sg_id" {
  description = "ID của Security Group cho EKS cluster"
  value       = aws_security_group.eks_cluster_sg.id
}

output "eks_nodes_sg_id" {
  description = "ID của Security Group cho EKS worker nodes"
  value       = aws_security_group.eks_nodes_sg.id
}

output "rds_sg_id" {
  description = "ID of RDS security group"
  value       = aws_security_group.rds_sg.id
}

output "docdb_sg_id" {
  description = "ID of DocumentDB security group"
  value       = aws_security_group.docdb_sg.id
}

// Thêm vào cuối file

output "efs_sg_id" {
  description = "ID của Security Group cho EFS"
  value       = aws_security_group.efs_sg.id
}