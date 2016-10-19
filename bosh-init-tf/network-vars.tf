# input variables

variable "ext_net_id" {
  description = "OpenStack external network id to create router interface port"
}

variable "ext_net_cidr" {
  description = "OpenStack external network cidr to define ingress security group rules"
}

variable "availability_zone" {
  description = "OpenStack availability zone name"
}

variable "dns_nameservers" {
  description = "Comma-separated list of DNS server IPs"
  default = "8.8.8.8"
}
