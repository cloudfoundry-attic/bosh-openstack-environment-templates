# input variables

# key pair
variable "keypair_suffix" {
  description = "Disambiguate keypairs with this suffix"
  default = ""
}

# external network coordinates
variable "ext_net_name" {
  description = "OpenStack external network name to register floating IP"
}

# region/zone coordinates
variable "region_name" {
  description = "OpenStack region name"
}

