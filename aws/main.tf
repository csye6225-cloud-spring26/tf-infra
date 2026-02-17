terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0, < 7.0.0"
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
  disable_api_termination = false

  root_block_device {
    volume_size           = var.webapp_root_volume_size
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-webapp"
  })
}
