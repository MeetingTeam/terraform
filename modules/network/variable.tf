# Environment
variable "env" {
  type = string
  default = "dev"
}

# Type
variable "type" {
  type = string
}

# Stack name
variable "cluster_name" {
  type = string
}

# VPC CIDR
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# Public subnet CIDRs
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# Private subnet CIDRs for applications
variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

# Private subnet CIDRs for data
variable "private_data_subnet_cidrs" {
  description = "CIDR blocks for private data subnets"
  type        = list(string)
  default     = ["10.0.5.0/24", "10.0.6.0/24"]
}

# AWS Region
variable "region" {
  type    = string
  default = "ap-southeast-1"
}

# Availability Zones
variable "availability_zones" {
  type    = list(string)
  default = ["ap-southeast-1a", "ap-southeast-1b"]
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}