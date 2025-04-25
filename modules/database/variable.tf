##########################################
# Chung
##########################################
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "env" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "private_data_subnet_ids" {
  description = "List of private data subnet IDs"
  type        = list(string)
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

variable "create_mysql" {
  description = "Whether to create MySQL RDS instance"
  type        = bool
  default     = false
}

variable "create_documentdb" {
  description = "Whether to create DocumentDB cluster"
  type        = bool
  default     = false
}

##########################################
# RDS MySQL
##########################################
variable "rds_sg_id" {
  description = "Security group ID for RDS"
  type        = string
  default     = ""
}

variable "mysql_db_name" {
  description = "Name of the MySQL database"
  type        = string
  default     = "appdb"
}

variable "mysql_username" {
  description = "Username for MySQL"
  type        = string
  default     = "dbadmin"  # Thay đổi từ "admin"
}

variable "mysql_password" {
  description = "Password for MySQL"
  type        = string
  sensitive   = true
  default     = ""
}

variable "mysql_instance_class" {
  description = "Instance class for MySQL"
  type        = string
  default     = "db.t3.medium"
}

variable "mysql_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "mysql_multi_az" {
  description = "Whether to enable Multi-AZ for MySQL"
  type        = bool
  default     = true
}

variable "mysql_allocated_storage" {
  description = "Allocated storage for MySQL in GB"
  type        = number
  default     = 20
}

##########################################
# DocumentDB
##########################################
variable "docdb_sg_id" {
  description = "Security group ID for DocumentDB"
  type        = string
  default     = ""
}

variable "docdb_username" {
  description = "Username for DocumentDB"
  type        = string
  default     = "dbadmin"
}

variable "docdb_password" {
  description = "Password for DocumentDB"
  type        = string
  sensitive   = true
  default     = ""
}

variable "docdb_instance_class" {
  description = "Instance class for DocumentDB"
  type        = string
  default     = "db.t3.medium"
}

variable "docdb_instance_count" {
  description = "Number of DocumentDB instances"
  type        = number
  default     = 2
}

variable "docdb_deletion_protection" {
  description = "Whether to enable deletion protection for DocumentDB"
  type        = bool
  default     = false
}