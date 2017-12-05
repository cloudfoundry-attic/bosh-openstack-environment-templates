output "network_cidr" {
  value = "${openstack_networking_subnet_v2.bosh_subnet.cidr}"
}

output "network_gateway_ip" {
  value = "${openstack_networking_subnet_v2.bosh_subnet.gateway_ip}"
}

output "network_dns" {
  value = "[${join(",", openstack_networking_subnet_v2.bosh_subnet.dns_nameservers)}]"
}

output "network_id" {
  value = "${openstack_networking_network_v2.bosh.id}"
}

output "director_private_ip" {
  value = "${cidrhost(openstack_networking_subnet_v2.bosh_subnet.cidr, 10)}"
}

output "router_id" {
  value = "${openstack_networking_router_v2.bosh_router.id}"
}
