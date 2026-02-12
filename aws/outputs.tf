output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.csye6225_vpc.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets."
  value       = [for subnet in aws_subnet.csye6225_public_subnet : subnet.id]
}

output "private_subnet_ids" {
  description = "IDs of private subnets."
  value       = [for subnet in aws_subnet.csye6225_private_subnet : subnet.id]
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.csye6225_igw.id
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.csye6225_public_rt.id
}

output "private_route_table_id" {
  description = "ID of the private route table."
  value       = aws_route_table.csye6225_private_rt.id
}
