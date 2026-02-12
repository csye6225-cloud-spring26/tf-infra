terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0.0, < 8.0.0"
    }
  }
}

locals {
  name_prefix = "${var.app_name}-${var.env_name}"

  # Check if multiple VPCs are requested; if not, use a single default name.
  vpc_names = length(var.vpc_suffixes) > 0 ? [
    for suffix in var.vpc_suffixes : "${local.name_prefix}-${suffix}"
  ] : [local.name_prefix]

  # Use explicit CIDRs if provided, otherwise auto-generate from VPC CIDR
  public_cidrs = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : [
    for idx in range(length(var.gcp_zones)) : cidrsubnet(var.gcp_vpc_cidr, var.subnet_newbits, idx)
  ]

  # Offset private subnets to avoid overlap with public subnets
  private_cidrs = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs : [
    for idx in range(length(var.gcp_zones)) : cidrsubnet(var.gcp_vpc_cidr, var.subnet_newbits, idx + length(var.gcp_zones))
  ]

  # Map subnets by index and VPC for for_each iteration
  public_subnet_defs = flatten([
    for vpc_name in local.vpc_names : [
      for idx, cidr in local.public_cidrs : {
        key      = "${vpc_name}-public-${idx}"
        vpc_name = vpc_name
        cidr     = cidr
        zone     = var.gcp_zones[idx]
        region   = var.gcp_region
        name     = "${vpc_name}-public-subnet-${idx + 1}-${var.gcp_zones[idx]}"
      }
    ]
  ])

  private_subnet_defs = flatten([
    for vpc_name in local.vpc_names : [
      for idx, cidr in local.private_cidrs : {
        key      = "${vpc_name}-private-${idx}"
        vpc_name = vpc_name
        cidr     = cidr
        zone     = var.gcp_zones[idx]
        region   = var.gcp_region
        name     = "${vpc_name}-private-subnet-${idx + 1}-${var.gcp_zones[idx]}"
      }
    ]
  ])

  public_subnets  = { for subnet in local.public_subnet_defs : subnet.key => subnet }
  private_subnets = { for subnet in local.private_subnet_defs : subnet.key => subnet }
}

# Custom VPC with manual subnet control
resource "google_compute_network" "csye6225_vpc" {
  for_each = toset(local.vpc_names)

  name                    = "${each.key}-vpc"
  auto_create_subnetworks = false
  routing_mode            = var.gcp_vpc_routing_mode
}

# Cloud Router for each VPC
resource "google_compute_router" "main" {
  for_each = toset(local.vpc_names)

  name    = "${each.key}-router"
  network = google_compute_network.csye6225_vpc[each.key].id
  region  = var.gcp_region
}

# Public subnets across zones
resource "google_compute_subnetwork" "public" {
  for_each = local.public_subnets

  name          = each.value.name
  ip_cidr_range = each.value.cidr
  region        = each.value.region
  network       = google_compute_network.csye6225_vpc[each.value.vpc_name].id

  private_ip_google_access = false
}

# Private subnets across zones
resource "google_compute_subnetwork" "private" {
  for_each = local.private_subnets

  name          = each.value.name
  ip_cidr_range = each.value.cidr
  region        = each.value.region
  network       = google_compute_network.csye6225_vpc[each.value.vpc_name].id

  private_ip_google_access = true
}

# Route for public instances to reach the internet
resource "google_compute_route" "public_internet" {
  for_each = toset(local.vpc_names)

  name       = "${each.key}-public-internet"
  network    = google_compute_network.csye6225_vpc[each.key].id
  dest_range = "0.0.0.0/0"
  priority   = var.gcp_public_route_priority

  next_hop_gateway = "default-internet-gateway"
  tags             = var.gcp_public_route_tags
}

# Allow ingress for HTTP, HTTPS, SSH on tagged instances
resource "google_compute_firewall" "allow_ingress" {
  for_each = toset(local.vpc_names)

  name    = "${each.key}-allow-ingress"
  network = google_compute_network.csye6225_vpc[each.key].id

  direction     = "INGRESS"
  priority      = var.gcp_allow_priority
  source_ranges = var.gcp_allow_source_ranges
  target_tags   = var.gcp_allow_target_tags

  allow {
    protocol = "tcp"
    ports    = var.gcp_allowed_tcp_ports
  }
}

# Deny all other ingress traffic
resource "google_compute_firewall" "deny_all" {
  for_each = toset(local.vpc_names)

  name    = "${each.key}-deny-all"
  network = google_compute_network.csye6225_vpc[each.key].id

  direction     = "INGRESS"
  priority      = var.gcp_deny_priority
  source_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }
}

