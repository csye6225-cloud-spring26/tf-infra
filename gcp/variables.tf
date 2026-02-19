variable "app_name" {
  description = "Application name used for resource naming."
  type        = string
}

variable "env_name" {
  description = "Environment name (e.g., dev, demo)."
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID."
  type        = string
}

variable "gcp_region" {
  description = "GCP region for resources."
  type        = string
}

variable "gcp_zones" {
  description = "List of GCP zones. Must match subnet CIDR list length."
  type        = list(string)
}

variable "vpc_suffixes" {
  description = "Optional list of suffixes to create multiple VPCs (e.g., [\"a\", \"b\"]). If empty, a single VPC is created."
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per zone)."
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per zone)."
  type        = list(string)
  default     = []
}

variable "subnet_newbits" {
  description = "New bits for subnet CIDR generation (e.g., 8 for /24s from a /16). Only used if explicit subnet CIDRs not provided."
  type        = number
  default     = 8
}

variable "gcp_vpc_cidr" {
  description = "CIDR block for the GCP VPC (used for automatic subnet generation)."
  type        = string
  default     = "10.10.0.0/16"
}

variable "gcp_vpc_routing_mode" {
  description = "Routing mode for the VPC network. Routes traffic only within the same region"
  type        = string
  default     = "REGIONAL"
}

variable "gcp_public_route_priority" {
  description = "Priority for the public internet route."
  type        = number
  default     = 1000
}

variable "gcp_public_route_tags" {
  description = "Network tags for instances that need public internet route."
  type        = list(string)
  default     = []
}

variable "gcp_allowed_tcp_ports" {
  description = "TCP ports to allow in the ingress firewall rule."
  type        = list(string)
  default     = ["22", "80", "443"]
}

variable "gcp_allow_source_ranges" {
  description = "Source CIDR ranges for allowed ingress traffic."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "gcp_allow_target_tags" {
  description = "Target network tags for allowed ingress traffic."
  type        = list(string)
  default     = []
}

variable "gcp_allow_priority" {
  description = "Priority for the allow ingress firewall rule."
  type        = number
  default     = 1000
}

variable "gcp_deny_priority" {
  description = "Priority for the deny-all firewall rule (higher number means lower priority)."
  type        = number
  default     = 65534
}

# ---------------------------------------------------------------------------
# Compute Engine / Image variables
# ---------------------------------------------------------------------------

variable "webapp_image_name" {
  description = "Explicit image name to use. When set, overrides the family-based lookup. Leave empty to use the latest image from the family."
  type        = string
  default     = ""
}

variable "webapp_image_family" {
  description = "Image family name for the custom GCP image built by Packer. Only used when webapp_image_name is empty."
  type        = string
  default     = "csye6225-webapp"
}

variable "webapp_machine_type" {
  description = "Machine type for the Compute Engine instance."
  type        = string
  default     = "e2-medium"
}

variable "webapp_boot_disk_size" {
  description = "Boot disk size in GB."
  type        = number
  default     = 25
}

variable "webapp_network_tag" {
  description = "Network tag applied to the webapp instance and used in firewall rules."
  type        = string
  default     = "webapp"
}

variable "webapp_port" {
  description = "TCP port the web application listens on."
  type        = number
  default     = 8080
}