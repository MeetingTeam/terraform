# Format tên cho các tài nguyên database
locals {
  # Chuyển đổi tên để đảm bảo chỉ có chữ cái, số và dấu gạch ngang
  formatted_name = replace(lower("${var.cluster_name}-${var.env}"), "_", "-")
  
  # Giới hạn độ dài tên
  name_prefix = substr(local.formatted_name, 0, min(45, length(local.formatted_name)))
  
  # Tên các resource
  rds_subnet_group_name = "${local.name_prefix}-rds-subnet"
  docdb_subnet_group_name = "${local.name_prefix}-docdb-subnet"
  rds_identifier = "${local.name_prefix}-mysql"
  docdb_cluster_identifier = "${local.name_prefix}-docdb"
}

##########################################
# DB Subnet Groups
##########################################
resource "aws_db_subnet_group" "rds_subnet_group" {
  count       = var.create_mysql ? 1 : 0
  name        = local.rds_subnet_group_name
  description = "Database subnet group for RDS"
  subnet_ids  = var.private_data_subnet_ids

  tags = merge(
    {
      Name        = local.rds_subnet_group_name
      Environment = var.env
    },
    var.tags
  )
}

resource "aws_docdb_subnet_group" "docdb_subnet_group" {
  count       = var.create_documentdb ? 1 : 0
  name        = local.docdb_subnet_group_name
  description = "Database subnet group for DocumentDB"
  subnet_ids  = var.private_data_subnet_ids

  tags = merge(
    {
      Name        = local.docdb_subnet_group_name
      Environment = var.env
    },
    var.tags
  )
}

##########################################
# MySQL RDS
##########################################
resource "aws_db_instance" "mysql" {
  count                  = var.create_mysql ? 1 : 0
  identifier             = local.rds_identifier
  engine                 = "mysql"
  engine_version         = var.mysql_engine_version
  instance_class         = var.mysql_instance_class
  allocated_storage      = var.mysql_allocated_storage
  storage_type           = "gp2"
  db_name                = var.mysql_db_name
  username               = var.mysql_username
  password               = var.mysql_password
  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group[0].name
  vpc_security_group_ids = [var.rds_sg_id]
  multi_az               = var.mysql_multi_az
  skip_final_snapshot    = true
  apply_immediately      = true
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  
  tags = merge(
    {
      Name        = local.rds_identifier
      Environment = var.env
    },
    var.tags
  )
}

##########################################
# DocumentDB
##########################################
resource "aws_docdb_cluster" "docdb" {
  count                         = var.create_documentdb ? 1 : 0
  cluster_identifier            = local.docdb_cluster_identifier
  engine                        = "docdb"
  master_username               = var.docdb_username
  master_password               = var.docdb_password
  backup_retention_period       = 7
  preferred_backup_window       = "02:00-03:00"
  preferred_maintenance_window  = "mon:03:00-mon:04:00"
  skip_final_snapshot           = true
  db_subnet_group_name          = aws_docdb_subnet_group.docdb_subnet_group[0].name
  vpc_security_group_ids        = [var.docdb_sg_id]
  storage_encrypted             = true
  deletion_protection           = var.docdb_deletion_protection
  
  tags = merge(
    {
      Name        = local.docdb_cluster_identifier
      Environment = var.env
    },
    var.tags
  )
}

resource "aws_docdb_cluster_instance" "docdb_instances" {
  count              = var.create_documentdb ? var.docdb_instance_count : 0
  identifier         = "${local.docdb_cluster_identifier}-${count.index}"
  cluster_identifier = aws_docdb_cluster.docdb[0].id
  instance_class     = var.docdb_instance_class
  
  tags = merge(
    {
      Name        = "${local.docdb_cluster_identifier}-${count.index}"
      Environment = var.env
    },
    var.tags
  )
}