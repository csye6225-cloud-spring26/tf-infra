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

output "app_security_group_id" {
  description = "ID of the application security group."
  value       = aws_security_group.app_sg.id
}

output "webapp_instance_id" {
  description = "ID of the web application EC2 instance."
  value       = aws_instance.webapp_instance.id
}

output "webapp_public_ip" {
  description = "Public IP address of the web application EC2 instance."
  value       = aws_instance.webapp_instance.public_ip
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for syllabus files."
  value       = aws_s3_bucket.syllabus_bucket.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for syllabus files."
  value       = aws_s3_bucket.syllabus_bucket.arn
}

output "db_security_group_id" {
  description = "ID of the database security group."
  value       = aws_security_group.db_sg.id
}

output "rds_endpoint" {
  description = "Endpoint of the RDS instance (hostname:port)."
  value       = aws_db_instance.csye6225_rds.endpoint
}

output "rds_hostname" {
  description = "Hostname of the RDS instance."
  value       = aws_db_instance.csye6225_rds.address
}

output "rds_port" {
  description = "Port of the RDS instance."
  value       = aws_db_instance.csye6225_rds.port
}

output "webapp_iam_role_arn" {
  description = "ARN of the IAM role attached to the webapp EC2 instance."
  value       = aws_iam_role.webapp_role.arn
}