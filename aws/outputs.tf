# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------
output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.csye6225_vpc.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = [for subnet in aws_subnet.csye6225_public_subnet : subnet.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
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

# ---------------------------------------------------------------------------
# Security Groups
# ---------------------------------------------------------------------------
output "lb_security_group_id" {
  description = "ID of the load balancer security group."
  value       = aws_security_group.lb_sg.id
}

output "app_security_group_id" {
  description = "ID of the application security group."
  value       = aws_security_group.app_sg.id
}

output "db_security_group_id" {
  description = "ID of the database security group."
  value       = aws_security_group.db_sg.id
}

# ---------------------------------------------------------------------------
# Load Balancer
# ---------------------------------------------------------------------------
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.webapp_alb.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer."
  value       = aws_lb.webapp_alb.zone_id
}

# ---------------------------------------------------------------------------
# Auto Scaling
# ---------------------------------------------------------------------------
output "asg_name" {
  description = "Name of the Auto Scaling Group."
  value       = aws_autoscaling_group.webapp_asg.name
}

output "launch_template_id" {
  description = "ID of the launch template."
  value       = aws_launch_template.webapp_lt.id
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------
output "s3_bucket_name" {
  description = "Name of the S3 bucket for syllabus files."
  value       = aws_s3_bucket.syllabus_bucket.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for syllabus files."
  value       = aws_s3_bucket.syllabus_bucket.arn
}

# ---------------------------------------------------------------------------
# DNS
# ---------------------------------------------------------------------------
output "webapp_url" {
  description = "URL to access the web application."
  value       = "http://${var.domain_name}"
}

# ---------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------
output "webapp_iam_role_arn" {
  description = "ARN of the IAM role attached to the webapp EC2 instance."
  value       = aws_iam_role.webapp_role.arn
}

# ---------------------------------------------------------------------------
# SNS / Lambda / DynamoDB
# ---------------------------------------------------------------------------
output "sns_topic_arn" {
  description = "ARN of the SNS topic for user signup notifications."
  value       = aws_sns_topic.user_signup.arn
}

output "lambda_function_name" {
  description = "Name of the email verification Lambda function."
  value       = aws_lambda_function.email_verification.function_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB email tracking table."
  value       = aws_dynamodb_table.email_tracking.name
}