output "efs_id" {
  description = "ID của EFS file system"
  value       = aws_efs_file_system.jenkins_cache.id
}

output "efs_arn" {
  description = "ARN của EFS file system"
  value       = aws_efs_file_system.jenkins_cache.arn
}

output "efs_dns_name" {
  description = "DNS name của EFS file system"
  value       = aws_efs_file_system.jenkins_cache.dns_name
}