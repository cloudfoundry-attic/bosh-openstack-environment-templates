output "keypair name" {
  value = "${openstack_compute_keypair_v2.bosh.name}"
}

output "allocated floating ip" {
  value = "${openstack_networking_floatingip_v2.bosh.address}"
}
