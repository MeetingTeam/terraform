##########################################
# MySQL outputs
##########################################
output "mysql_endpoint" {
  description = "MySQL endpoint"
  value       = try(aws_db_instance.mysql[0].endpoint, null)
}

output "mysql_address" {
  description = "MySQL address"
  value       = try(aws_db_instance.mysql[0].address, null)
}

output "mysql_port" {
  description = "MySQL port"
  value       = try(aws_db_instance.mysql[0].port, null)
}

output "mysql_name" {
  description = "MySQL database name"
  value       = var.create_mysql ? var.mysql_db_name : null
}

output "mysql_username" {
  description = "MySQL username"
  value       = var.create_mysql ? var.mysql_username : null
}

##########################################
# DocumentDB outputs
##########################################
output "documentdb_endpoint" {
  description = "DocumentDB cluster endpoint"
  value       = try(aws_docdb_cluster.docdb[0].endpoint, null)
}

output "documentdb_reader_endpoint" {
  description = "DocumentDB reader endpoint"
  value       = try(aws_docdb_cluster.docdb[0].reader_endpoint, null)
}

output "documentdb_port" {
  description = "DocumentDB port"
  value       = try(aws_docdb_cluster.docdb[0].port, null)
}

output "documentdb_instance_endpoints" {
  description = "List of DocumentDB instance endpoints"
  value       = try([for instance in aws_docdb_cluster_instance.docdb_instances : instance.endpoint], [])
}

output "documentdb_username" {
  description = "DocumentDB master username"
  value       = var.create_documentdb ? var.docdb_username : null
}