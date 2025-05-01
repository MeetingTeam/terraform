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

# Database Outputs
output "mysql_endpoint" {
  description = "MySQL endpoint"
  value       = module.database.mysql_endpoint
  sensitive   = true
}

output "mysql_address" {
  description = "MySQL address"
  value       = module.database.mysql_address
  sensitive   = true
}

output "mysql_port" {
  description = "MySQL port"
  value       = module.database.mysql_port
}

output "mysql_name" {
  description = "MySQL database name"
  value       = module.database.mysql_name
}

output "mysql_username" {
  description = "MySQL username"
  value       = module.database.mysql_username
  sensitive   = true
}

output "documentdb_endpoint" {
  description = "DocumentDB cluster endpoint"
  value       = module.database.documentdb_endpoint
  sensitive   = true
}

output "documentdb_reader_endpoint" {
  description = "DocumentDB reader endpoint"
  value       = module.database.documentdb_reader_endpoint
  sensitive   = true
}

output "documentdb_port" {
  description = "DocumentDB port"
  value       = module.database.documentdb_port
}

output "documentdb_instance_endpoints" {
  description = "List of DocumentDB instance endpoints"
  value       = module.database.documentdb_instance_endpoints
  sensitive   = true
}

output "documentdb_username" {
  description = "DocumentDB master username"
  value       = module.database.documentdb_username
  sensitive   = true
}