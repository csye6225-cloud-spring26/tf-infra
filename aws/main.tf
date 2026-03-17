terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0, < 7.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

locals {
  name_prefix = "${var.app_name}-${var.env_name}"

  # Prefer explicit CIDRs when provided; otherwise derive deterministic subnets from VPC CIDR.
  public_cidrs = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : [
    for idx in range(length(var.azs)) : cidrsubnet(var.vpc_cidr, var.subnet_newbits, idx)
  ]

  # Offset private subnets after public ones to avoid overlap.
  private_cidrs = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs : [
    for idx in range(length(var.azs)) : cidrsubnet(var.vpc_cidr, var.subnet_newbits, idx + length(var.azs))
  ]

  # Build subnet maps keyed by index for consistent for_each usage.
  public_subnets = {
    for idx, cidr in local.public_cidrs : tostring(idx) => {
      cidr = cidr
      az   = var.azs[idx]
      name = "${local.name_prefix}-public-subnet-${idx + 1}"
    }
  }

  private_subnets = {
    for idx, cidr in local.private_cidrs : tostring(idx) => {
      cidr = cidr
      az   = var.azs[idx]
      name = "${local.name_prefix}-private-subnet-${idx + 1}"
    }
  }
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

# VPC for the environment
resource "aws_vpc" "csye6225_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

# Internet Gateway for public subnet egress
resource "aws_internet_gateway" "csye6225_igw" {
  vpc_id = aws_vpc.csye6225_vpc.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# Public subnets across availability zones
resource "aws_subnet" "csye6225_public_subnet" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.csye6225_vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = each.value.name
  })
}

# Private subnets across availability zones
resource "aws_subnet" "csye6225_private_subnet" {
  for_each = local.private_subnets

  vpc_id                  = aws_vpc.csye6225_vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = each.value.name
  })
}

# Route table for public subnets
resource "aws_route_table" "csye6225_public_rt" {
  vpc_id = aws_vpc.csye6225_vpc.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

# Default route to the Internet Gateway
resource "aws_route" "csye6225_public_internet" {
  route_table_id         = aws_route_table.csye6225_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.csye6225_igw.id
}

# Route table for private subnets
resource "aws_route_table" "csye6225_private_rt" {
  vpc_id = aws_vpc.csye6225_vpc.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-private-rt"
  })
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "csye6225_public_assoc" {
  for_each = aws_subnet.csye6225_public_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.csye6225_public_rt.id
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "csye6225_private_assoc" {
  for_each = aws_subnet.csye6225_private_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.csye6225_private_rt.id
}

# ---------------------------------------------------------------------------
# Data source: look up the most recent custom AMI built by Packer
# ---------------------------------------------------------------------------
data "aws_ami" "webapp_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.webapp_ami_name_filter]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  owners = [var.webapp_ami_owner]
}

# ---------------------------------------------------------------------------
# Application Security Group
# ---------------------------------------------------------------------------
resource "aws_security_group" "app_sg" {
  name        = "${local.name_prefix}-app-sg"
  description = "Security group for web application EC2 instances"
  vpc_id      = aws_vpc.csye6225_vpc.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Application port
  ingress {
    description = "Application port"
    from_port   = var.webapp_port
    to_port     = var.webapp_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-app-sg"
  })
}

# ---------------------------------------------------------------------------
# EC2 Instance
# ---------------------------------------------------------------------------
resource "aws_instance" "webapp_instance" {
  ami                     = var.webapp_ami_id != "" ? var.webapp_ami_id : data.aws_ami.webapp_ami.id
  instance_type           = var.webapp_instance_type
  subnet_id               = values(aws_subnet.csye6225_public_subnet)[0].id
  key_name                = var.key_name
  vpc_security_group_ids  = [aws_security_group.app_sg.id]
  iam_instance_profile    = aws_iam_instance_profile.webapp_instance_profile.name
  disable_api_termination = false

  root_block_device {
    volume_size           = var.webapp_root_volume_size
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = <<EOF
#!/bin/bash
set -e

# -----------------------------------------------
# Write .env file with RDS and S3 configuration
# -----------------------------------------------
cat > /opt/csye6225/.env <<ENVFILE
DATABASE_URL=postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.csye6225_rds.address}:5432/${var.db_name}
PORT=${var.webapp_port}
NODE_ENV=production
S3_BUCKET_NAME=${aws_s3_bucket.syllabus_bucket.id}
AWS_REGION=${var.aws_region}
ENVFILE

# -----------------------------------------------
# Set correct ownership (csye6225 user owns the app)
# -----------------------------------------------
chown csye6225:csye6225 /opt/csye6225/.env
chmod 640 /opt/csye6225/.env

# -----------------------------------------------
# Restart the webapp service so it picks up the new .env
# Prisma migrate deploy runs automatically via ExecStartPre
# -----------------------------------------------
systemctl daemon-reload
systemctl restart webapp
EOF

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-webapp"
  })
}

# ---------------------------------------------------------------------------
# S3 Bucket for Syllabus Files
# ---------------------------------------------------------------------------

# Generate a UUID for the bucket name (globally unique, no info leakage)
resource "random_uuid" "s3_bucket_name" {}

# The S3 bucket itself
resource "aws_s3_bucket" "syllabus_bucket" {
  bucket        = random_uuid.s3_bucket_name.result
  force_destroy = true # Allows terraform destroy even if bucket has objects

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-syllabus-bucket"
  })
}

# Block ALL public access — defense in depth
resource "aws_s3_bucket_public_access_block" "syllabus_bucket_public_access" {
  bucket = aws_s3_bucket.syllabus_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Default encryption — AES-256 (SSE-S3), AWS manages the keys
resource "aws_s3_bucket_server_side_encryption_configuration" "syllabus_bucket_encryption" {
  bucket = aws_s3_bucket.syllabus_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle policy — transition to STANDARD_IA after 30 days to save costs
resource "aws_s3_bucket_lifecycle_configuration" "syllabus_bucket_lifecycle" {
  bucket = aws_s3_bucket.syllabus_bucket.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

# ---------------------------------------------------------------------------
# Database Security Group
# ---------------------------------------------------------------------------
resource "aws_security_group" "db_sg" {
  name        = "${local.name_prefix}-db-sg"
  description = "Security group for RDS instances only allows traffic from application SG"
  vpc_id      = aws_vpc.csye6225_vpc.id

  # Allow PostgreSQL traffic ONLY from the application security group
  ingress {
    description     = "PostgreSQL from application SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id] # <-- SG chaining, NOT a CIDR block
  }

  # No egress rule defined = no outbound traffic allowed by default
  # (RDS doesn't need to initiate outbound connections)

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-db-sg"
  })
}

# ---------------------------------------------------------------------------
# RDS Parameter Group
# ---------------------------------------------------------------------------
resource "aws_db_parameter_group" "csye6225_pg" {
  name        = "${local.name_prefix}-pg"
  family      = "postgres16" # Must match your RDS engine version
  description = "Custom parameter group for CSYE6225 PostgreSQL RDS"

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-pg"
  })
}

# ---------------------------------------------------------------------------
# RDS Subnet Group — tells RDS to place instances in private subnets
# ---------------------------------------------------------------------------
resource "aws_db_subnet_group" "csye6225_db_subnet_group" {
  name        = "${local.name_prefix}-db-subnet-group"
  description = "Private subnets for RDS instances"

  # Collect all private subnet IDs into the group
  subnet_ids = [for subnet in aws_subnet.csye6225_private_subnet : subnet.id]

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-db-subnet-group"
  })
}

# ---------------------------------------------------------------------------
# RDS Instance
# ---------------------------------------------------------------------------
resource "aws_db_instance" "csye6225_rds" {
  # Identity
  identifier = "csye6225"
  db_name    = var.db_name

  # Engine
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  # Credentials
  username = var.db_username
  password = var.db_password

  # Storage
  allocated_storage = 20
  storage_type      = "gp2"

  # Networking — private subnet, NOT publicly accessible
  db_subnet_group_name   = aws_db_subnet_group.csye6225_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false

  # Configuration
  parameter_group_name = aws_db_parameter_group.csye6225_pg.name
  multi_az             = false

  # Lifecycle — skip snapshot on destroy so terraform destroy works cleanly
  skip_final_snapshot = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-rds"
  })
}

# ---------------------------------------------------------------------------
# IAM Role for EC2 — allows the webapp to access AWS services
# ---------------------------------------------------------------------------

# Trust policy: allows EC2 service to assume this role
resource "aws_iam_role" "webapp_role" {
  name = "${local.name_prefix}-webapp-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-webapp-role"
  })
}

# S3 policy: least privilege — only PutObject, GetObject, DeleteObject
# scoped to ONLY our syllabus bucket
resource "aws_iam_policy" "webapp_s3_policy" {
  name        = "${local.name_prefix}-webapp-s3-policy"
  description = "Allows webapp to put, get, and delete objects in the syllabus S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.syllabus_bucket.arn}/*" # Only objects IN this bucket
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-webapp-s3-policy"
  })
}

# Attach the S3 policy to the role
resource "aws_iam_role_policy_attachment" "webapp_s3_attachment" {
  role       = aws_iam_role.webapp_role.name
  policy_arn = aws_iam_policy.webapp_s3_policy.arn
}

# ---------------------------------------------------------------------------
# CloudWatch policy: allows the agent to push logs and custom metrics
# ---------------------------------------------------------------------------
resource "aws_iam_policy" "webapp_cloudwatch_policy" {
  name        = "${local.name_prefix}-webapp-cloudwatch-policy"
  description = "Allows CloudWatch agent to push logs and custom metrics"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-webapp-cloudwatch-policy"
  })
}

# Attach CloudWatch policy to the same webapp role
resource "aws_iam_role_policy_attachment" "webapp_cloudwatch_attachment" {
  role       = aws_iam_role.webapp_role.name
  policy_arn = aws_iam_policy.webapp_cloudwatch_policy.arn
}

# Instance profile — the bridge between EC2 and the IAM role
resource "aws_iam_instance_profile" "webapp_instance_profile" {
  name = "${local.name_prefix}-webapp-instance-profile"
  role = aws_iam_role.webapp_role.name

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-webapp-instance-profile"
  })
}

# ---------------------------------------------------------------------------
# DNS — Route 53 A Record
# ---------------------------------------------------------------------------

# Optional data source: look up the zone by name if zone_id is not provided
data "aws_route53_zone" "app_zone" {
  count = var.zone_id == "" ? 1 : 0
  name  = var.domain_name
}

locals {
  resolved_zone_id = var.zone_id != "" ? var.zone_id : data.aws_route53_zone.app_zone[0].zone_id
}

resource "aws_route53_record" "webapp_a_record" {
  zone_id = local.resolved_zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 60
  records = [aws_instance.webapp_instance.public_ip]
}