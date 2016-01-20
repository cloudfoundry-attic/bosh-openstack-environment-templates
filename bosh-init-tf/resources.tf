# provider configuration
provider "openstack" {
  auth_url    = "${var.auth_url}"
  user_name   = "${var.user_name}"
  password    = "${var.password}"
  tenant_name = "${var.tenant_id}"
  insecure    = "${var.insecure}"
}

# key pairs
resource "openstack_compute_keypair_v2" "bosh" {
  region     = "${var.region_name}"
  name       = "bosh${var.keypair_suffix}"
  public_key = "${replace(\"${file(\"bosh.key.pub\")}\",\"\n\",\"\")}"
}

# security group
resource "openstack_compute_secgroup_v2" "bosh" {
  region      = "${var.region_name}"
  name        = "bosh"
  description = "BOSH Security Group"

  # SSH access from bosh-init
  rule {
    ip_protocol = "tcp"
    from_port   = "22"
    to_port     = "22"
    cidr        = "0.0.0.0/0"
  }

  # BOSH Agent access from bosh-init
  rule {
    ip_protocol = "tcp"
    from_port   = "6868"
    to_port     = "6868"
    cidr        = "0.0.0.0/0"
  }

  # BOSH Director access from CLI
  rule {
    ip_protocol = "tcp"
    from_port   = "25555"
    to_port     = "25555"
    cidr        = "0.0.0.0/0"
  }

  # Management and data access
  rule {
    ip_protocol = "tcp"
    from_port   = "1"
    to_port     = "65535"
    self        = true
  }
}

# floating ips
resource "openstack_compute_floatingip_v2" "bosh" {
  region = "${var.region_name}"
  pool   = "${var.ext_net_name}"
}
