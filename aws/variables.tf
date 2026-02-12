variable "app_name" {
	description = "Application name used for resource naming."
	type        = string
}

variable "env_name" {
	description = "Environment name (e.g., dev, demo)."
	type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
}

variable "aws_region" {
	description = "AWS region for all resources."
	type        = string
}

variable "vpc_cidr" {
	description = "CIDR block for the VPC."
	type        = string
}

variable "azs" {
	description = "List of availability zones to use. Must match subnet CIDR list length."
	type        = list(string)
}

variable "public_subnet_cidrs" {
	description = "CIDR blocks for public subnets (one per AZ)."
	type        = list(string)
	default     = []
}

variable "private_subnet_cidrs" {
	description = "CIDR blocks for private subnets (one per AZ)."
	type        = list(string)
	default     = []
}

variable "subnet_newbits" {
	description = "New bits for subnet CIDR generation (e.g., 8 for /24s from a /16)."
	type        = number
	default     = 8
}

variable "tags" {
	description = "Common tags applied to resources."
	type        = map(string)
	default     = {}
}
