provider "openstack" {
  auth_url    = "${var.auth_url}"
  user_name   = "${var.user_name}"
  password    = "${var.password}"
  tenant_name = "${var.project_name}"
  domain_name = "${var.domain_name}"
  insecure    = "${var.insecure}"
  cacert_file = "${var.cacert_file}"
}

variable "auth_url" {
  description = "Authentication endpoint URL for OpenStack provider (only scheme+host+port, but without path!)"
}

variable "domain_name" {
  description = "OpenStack domain name"
}

variable "user_name" {
  description = "OpenStack pipeline technical user name"
}

variable "password" {
  description = "OpenStack user password"
}

variable "project_name" {
  description = "OpenStack project/tenant name"
}

variable "insecure" {
  default = "false"
  description = "SSL certificate validation"
}

variable "cacert_file" {
  default = ""
  description = "Path to trusted CA certificate for OpenStack in PEM format"
}

variable "region_name" {
  description = "OpenStack region name"
}

variable "dns_nameservers" {
  type    = "list"
  description = "DNS server IPs"
}

variable "availability_zones" {
  type = "list"
}

variable "use_local_blobstore" {
  default = "true"
}

variable "use_tcp_router" {
  default = "true"
  description = "OpenStack external network name to register floating IP"
}

variable "ext_net_name" {
  description = "OpenStack external network name to register floating IP"
}

variable "bosh_router_id" {
  description = "ID of the router, which has an interface to the BOSH network"
}

variable "num_tcp_ports" {
  default = 100
  description = "Number of tcp ports, created for tcp routing in Cloud Foundry. Creates required listeners, pools and security rules."
}

resource "openstack_networking_network_v2" "cf_net" {
  count          = "${length(var.availability_zones)}"
  region         = "${var.region_name}"
  name           = "cf-z${count.index}"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "cf_subnet" {
  count          = "${length(var.availability_zones)}"
  region           = "${var.region_name}"
  network_id       = "${element(openstack_networking_network_v2.cf_net.*.id, count.index)}"
  cidr             = "${cidrsubnet("10.0.0.0/16", 4, count.index+1)}"
  ip_version       = 4
  name           = "cf-z${count.index}-sub"
  allocation_pools = {
    start = "${cidrhost(cidrsubnet("10.0.0.0/16", 4, count.index+1), 2)}"
    end   = "${cidrhost(cidrsubnet("10.0.0.0/16", 4, count.index+1), 50)}"
  }
  gateway_ip       = "${cidrhost(cidrsubnet("10.0.0.0/16", 4, count.index+1), 1)}"
  enable_dhcp      = "true"
  dns_nameservers = "${var.dns_nameservers}"
}

resource "openstack_networking_secgroup_v2" "cf_sec_group" {
  region      = "${var.region_name}"
  name        = "cf"
  description = "cloud foundry security group"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_udp" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "udp"
  remote_group_id = "${openstack_networking_secgroup_v2.cf_sec_group.id}"
  security_group_id = "${openstack_networking_secgroup_v2.cf_sec_group.id}"
  region = "${var.region_name}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_icmp" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "icmp"
  remote_group_id = "${openstack_networking_secgroup_v2.cf_sec_group.id}"
  security_group_id = "${openstack_networking_secgroup_v2.cf_sec_group.id}"
  region = "${var.region_name}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_tcp_self" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  remote_group_id = "${openstack_networking_secgroup_v2.cf_sec_group.id}"
  security_group_id = "${openstack_networking_secgroup_v2.cf_sec_group.id}"
  region = "${var.region_name}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_tcp_22" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 22
  port_range_max = 22
  remote_group_id = "${openstack_networking_secgroup_v2.bosh_sec_group.id}"
  security_group_id = "${openstack_networking_secgroup_v2.cf_sec_group.id}"
  region = "${var.region_name}"
}

resource "openstack_networking_secgroup_v2" "bosh_sec_group" {
  region      = "${var.region_name}"
  name        = "cf-deployment-for-bosh"
  description = "Security group must be assigned to BOSH director VM. This enables NATS communication and allows the CF VMs to download compiled packages from the local blobstore"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_tcp_9443" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 9443
  port_range_max = 9443
  remote_group_id = "${openstack_networking_secgroup_v2.cf_sec_group.id}"
  security_group_id = "${openstack_networking_secgroup_v2.bosh_sec_group.id}"
  region = "${var.region_name}"
}


resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_nats_cf" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 4222
  port_range_max = 4222
  remote_group_id = "${openstack_networking_secgroup_v2.cf_sec_group.id}"
  security_group_id = "${openstack_networking_secgroup_v2.bosh_sec_group.id}"
  region = "${var.region_name}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_local_blobstore_cf" {
  count = "${var.use_local_blobstore == "true" ? 1 : 0}"
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 25250
  port_range_max = 25250
  remote_group_id = "${openstack_networking_secgroup_v2.cf_sec_group.id}"
  security_group_id = "${openstack_networking_secgroup_v2.bosh_sec_group.id}"
  region = "${var.region_name}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_registry_cf" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 25777
  port_range_max = 25777
  remote_group_id = "${openstack_networking_secgroup_v2.cf_sec_group.id}"
  security_group_id = "${openstack_networking_secgroup_v2.bosh_sec_group.id}"
  region = "${var.region_name}"
}

resource "openstack_networking_secgroup_v2" "cf_https_router_sec_group" {
  region      = "${var.region_name}"
  name        = "cf-lb-https-router"
  description = "Security group which will be assigned to the cloud foundry router VM to receive TCP traffic from the load balancer on port 443"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_tcp_443_cf_https_router" {
  count = "${length(var.availability_zones)}"
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 443
  port_range_max = 443
  remote_ip_prefix = "${element(openstack_networking_subnet_v2.cf_subnet.*.cidr, count.index)}"
  security_group_id = "${openstack_networking_secgroup_v2.cf_https_router_sec_group.id}"
  region = "${var.region_name}"
}

resource "openstack_networking_secgroup_v2" "cf_diego_brain_sec_group" {
  region      = "${var.region_name}"
  name        = "cf-lb-ssh-diego-brain"
  description = "Security group which will be assigned to the cloud foundry diego brain VM to receive TCP traffic from the load balancer on port 2222"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_tcp_2222_cf_diego_brain" {
  count = "${length(var.availability_zones)}"
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 2222
  port_range_max = 2222
  remote_ip_prefix = "${element(openstack_networking_subnet_v2.cf_subnet.*.cidr, count.index)}"
  security_group_id = "${openstack_networking_secgroup_v2.cf_diego_brain_sec_group.id}"
  region = "${var.region_name}"
}

resource "openstack_networking_secgroup_v2" "cf_lb_sec_group" {
  region      = "${var.region_name}"
  name        = "cf-lb"
  description = "Security group which will be assigned to the cf load balancer"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_tcp_443_cf_lb" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 443
  port_range_max = 443
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.cf_lb_sec_group.id}"
  region = "${var.region_name}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_tcp_2222_cf_lb" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 2222
  port_range_max = 2222
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.cf_lb_sec_group.id}"
  region = "${var.region_name}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_tcp_ports_cf_lb" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 1024
  port_range_max = "${1024 + var.num_tcp_ports - 1}"
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.cf_lb_sec_group.id}"
  region = "${var.region_name}"
}

resource "openstack_lb_loadbalancer_v2" "cf-lb" {
  name = "cf-lb"
  vip_subnet_id = "${openstack_networking_subnet_v2.cf_subnet.0.id}"
  security_group_ids = ["${openstack_networking_secgroup_v2.cf_lb_sec_group.id}"]
  region = "${var.region_name}"
}

resource "openstack_networking_floatingip_v2" "lb_floating" {
  pool = "${var.ext_net_name}"
  port_id = "${openstack_lb_loadbalancer_v2.cf-lb.vip_port_id}"
  region = "${var.region_name}"
}

resource "openstack_lb_listener_v2" "cf_https_listener" {
  region = "${var.region_name}"
  protocol        = "TCP"
  protocol_port   = 443
  name = "cf-https-listener"
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.cf-lb.id}"
}

resource "openstack_lb_pool_v2" "cf_https_pool" {
  region = "${var.region_name}"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  name = "cf-https-pool"
  listener_id = "${openstack_lb_listener_v2.cf_https_listener.id}"
}

resource "openstack_lb_listener_v2" "cf_ssh_listener" {
  region = "${var.region_name}"
  protocol        = "TCP"
  protocol_port   = 2222
  name = "cf-ssh-listener"
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.cf-lb.id}"
}

resource "openstack_lb_pool_v2" "cf_ssh_pool" {
  region = "${var.region_name}"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  name = "cf-ssh-pool"
  listener_id = "${openstack_lb_listener_v2.cf_ssh_listener.id}"
}

resource "openstack_lb_listener_v2" "cf_tcp_listener" {
  count = "${var.use_tcp_router == "true" ? var.num_tcp_ports : 0}"
  region = "${var.region_name}"
  protocol        = "TCP"
  protocol_port   = "${1024 + count.index}"
  name = "cf-tcp-listener-${1024 + count.index}"
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.cf-lb.id}"
}

resource "openstack_lb_pool_v2" "cf_tcp_pool" {
  count = "${var.use_tcp_router == "true" ? var.num_tcp_ports : 0}"
  region = "${var.region_name}"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  name = "cf-tcp-pool-${1024 + count.index}"
  listener_id = "${element(openstack_lb_listener_v2.cf_tcp_listener.*.id, count.index)}"
}

resource "openstack_networking_secgroup_v2" "cf_lb_tcp_router_sec_group" {
  count = "${var.use_tcp_router == "true" ? 1 : 0}"
  region      = "${var.region_name}"
  name        = "cf-lb-tcp-router"
  description = "Security group which will be assigned to the cloud foundry tcp router VM to receive TCP traffic from the load balancer on port 1024-${1024 + var.num_tcp_ports - 1}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_tcp_ports_cf_tcp_router" {
  count = "${var.use_tcp_router == "true" ? length(var.availability_zones) : 0}"
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 1024
  port_range_max = "${1024 + var.num_tcp_ports - 1}"
  remote_ip_prefix = "${element(openstack_networking_subnet_v2.cf_subnet.*.cidr, count.index)}"
  security_group_id = "${openstack_networking_secgroup_v2.cf_lb_tcp_router_sec_group.id}"
  region = "${var.region_name}"
}

resource "openstack_networking_router_interface_v2" "cf_router_interface" {
  count = "${length(var.availability_zones)}"
  router_id = "${var.bosh_router_id}"
  subnet_id = "${element(openstack_networking_subnet_v2.cf_subnet.*.id, count.index)}"
  region = "${var.region_name}"
}

output "network_id" {
  value = "${openstack_networking_network_v2.cf_net.*.id}"
}

output "security group to be assigned to BOSH vm" {
  value = "${openstack_networking_secgroup_v2.bosh_sec_group.name}"
}

output "Load balancer floating ip" {
  value = "${openstack_networking_floatingip_v2.lb_floating.address}"
}
