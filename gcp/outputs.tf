
output "network_ids" {
  description = "IDs of VPC networks by name."
  value       = { for name, net in google_compute_network.csye6225_vpc : name => net.id }
}

output "public_subnet_ids" {
  description = "IDs of public subnets by VPC name."
  value = {
    for vpc_name in local.vpc_names : vpc_name => [
      for subnet in google_compute_subnetwork.public : subnet.id
      if subnet.network == google_compute_network.csye6225_vpc[vpc_name].id
    ]
  }
}

output "private_subnet_ids" {
  description = "IDs of private subnets by VPC name."
  value = {
    for vpc_name in local.vpc_names : vpc_name => [
      for subnet in google_compute_subnetwork.private : subnet.id
      if subnet.network == google_compute_network.csye6225_vpc[vpc_name].id
    ]
  }
}

output "public_subnet_names" {
  description = "Names of public subnets by VPC name."
  value = {
    for vpc_name in local.vpc_names : vpc_name => [
      for subnet in google_compute_subnetwork.public : subnet.name
      if subnet.network == google_compute_network.csye6225_vpc[vpc_name].id
    ]
  }
}

output "private_subnet_names" {
  description = "Names of private subnets by VPC name."
  value = {
    for vpc_name in local.vpc_names : vpc_name => [
      for subnet in google_compute_subnetwork.private : subnet.name
      if subnet.network == google_compute_network.csye6225_vpc[vpc_name].id
    ]
  }
}
