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

# ---------------------------------------------------------------------------
# EC2 / AMI variables
# ---------------------------------------------------------------------------

variable "webapp_ami_name_filter" {
  description = "Name filter pattern for the custom AMI (e.g., 'csye6225-*')."
  type        = string
  default     = "csye6225-*"
}

variable "webapp_ami_id" {
  description = "Explicit AMI ID to use. When set, overrides the dynamic lookup. Leave empty to use the latest AMI matching the name filter."
  type        = string
  default     = ""
}

variable "webapp_ami_owner" {
  description = "AWS account ID that owns the custom AMI. Use 'self' for the current account."
  type        = string
  default     = "self"
}

variable "webapp_instance_type" {
  description = "EC2 instance type for the web application."
  type        = string
  default     = "t2.micro"
}

variable "webapp_root_volume_size" {
  description = "Root EBS volume size in GB for the web application instance."
  type        = number
  default     = 25
}

variable "webapp_port" {
  description = "TCP port the web application listens on."
  type        = number
  default     = 8080
}

variable "key_name" {
  description = "Name of an existing AWS EC2 key pair for SSH access."
  type        = string
}
