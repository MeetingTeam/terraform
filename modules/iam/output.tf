output "eks_cluster_role_arn" {
  description = "ARN của IAM Role cho EKS Cluster"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "eks_node_role_arn" {
  description = "ARN của IAM Role cho EKS Node Group"
  value       = aws_iam_role.eks_node_role.arn
}

output "autoscaler_policy_arn" {
  description = "ARN của chính sách Cluster Autoscaler"
  value       = aws_iam_policy.autoscaler.arn
}

output "eks_node_instance_profile_arn" {
  description = "ARN của Instance Profile cho EKS worker nodes"
  value       = aws_iam_instance_profile.eks_node_profile.arn
}