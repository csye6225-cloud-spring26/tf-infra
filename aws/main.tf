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

# VPC for the environment
resource "aws_vpc" "csye6225_vpc" {
  cidr_block               = var.vpc_cidr
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
