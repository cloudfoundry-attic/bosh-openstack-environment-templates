output "default_key_name" {
  value = "${openstack_compute_keypair_v2.bosh.name}"
}

output "external_ip" {
  value = "${openstack_networking_floatingip_v2.bosh.address}"
}
