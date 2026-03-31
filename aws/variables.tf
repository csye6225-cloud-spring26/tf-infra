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

variable "statsd_port" {
  description = "UDP port used by StatsD for custom metrics ingestion."
  type        = number
  default     = 8125
}

variable "key_name" {
  description = "Name of an existing AWS EC2 key pair for SSH access."
  type        = string
}

# ---------------------------------------------------------------------------
# RDS variables
# ---------------------------------------------------------------------------
variable "db_engine_version" {
  description = "PostgreSQL engine version for RDS."
  type        = string
  default     = "16"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the database to create."
  type        = string
  default     = "csye6225"
}

variable "db_username" {
  description = "Master username for the RDS instance."
  type        = string
  default     = "csye6225"
}

variable "db_password" {
  description = "Master password for the RDS instance."
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# DNS / Route 53 variables
# ---------------------------------------------------------------------------
variable "domain_name" {
  description = "Fully qualified domain name for the environment (e.g., dev.srikanthsharma.me)."
  type        = string
}

variable "zone_id" {
  description = "Route 53 hosted zone ID. If empty, Terraform will look it up using domain_name."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Lambda / Email variables
# ---------------------------------------------------------------------------
variable "lambda_zip_path" {
  description = "Path to the Lambda function deployment package (ZIP file)."
  type        = string
  default     = "serverless.zip"
}

variable "mailgun_api_key" {
  description = "Mailgun API key for sending verification emails."
  type        = string
  sensitive   = true
}

variable "mailgun_domain" {
  description = "Mailgun sending domain (e.g., srikanthsharma.me)."
  type        = string
}