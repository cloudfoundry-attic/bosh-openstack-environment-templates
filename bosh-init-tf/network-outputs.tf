output "network CIDR" {
  value = "${openstack_networking_subnet_v2.bosh_subnet.cidr}"
}

output "network gateway IP" {
  value = "${openstack_networking_subnet_v2.bosh_subnet.gateway_ip}"
}

output "network dns" {
  value = "[${join(",", openstack_networking_subnet_v2.bosh_subnet.dns_nameservers)}]"
}

output "network id" {
  value = "${openstack_networking_network_v2.bosh.id}"
}
