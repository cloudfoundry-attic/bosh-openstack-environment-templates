# input variables

# key pair
variable "keypair_suffix" {
  description = "Disambiguate keypairs with this suffix"
  default = ""
}


# security group
variable "security_group_suffix" {
  description = "Disambiguate security groups with this suffix"
  default = ""
}
