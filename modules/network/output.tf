output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
}

output "private_app_subnet_ids" {
  description = "List of private application subnet IDs"
  value       = [aws_subnet.private_app_subnet1.id, aws_subnet.private_app_subnet2.id]
}

output "private_data_subnet_ids" {
  description = "List of private data subnet IDs"
  value       = [aws_subnet.private_data_subnet1.id, aws_subnet.private_data_subnet2.id]
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = [aws_nat_gateway.nat_gateway1.id, aws_nat_gateway.nat_gateway2.id]
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public_route_table.id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = [aws_route_table.private_route_table1.id, aws_route_table.private_route_table2.id]
}

output "private_data_subnet1_id" {
  description = "ID of the first private data subnet"
  value       = aws_subnet.private_data_subnet1.id
}

output "private_data_subnet2_id" {
  description = "ID of the second private data subnet"
  value       = aws_subnet.private_data_subnet2.id
}