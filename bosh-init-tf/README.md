### Prepare an OpenStack environment

Prerequisite: Install [terraform](https://www.terraform.io/intro/getting-started/install.html)

1. Copy `terraform.tfvars.template` to `terraform.tfvars`
1. Configure `terraform.tfvars`
1. Execute `prepare_openstack_env.sh`

The script will generate a key pair. It will output the allocated floating ip.
Make sure to treat the created `terraform.tfstate` files with care.

### Delete the OpenStack environment

If you have the `terraform.tfstate` file available `destroy_openstack_env.sh` will
destroy the created resources.

*NOTE:* The template uses Keystone V2
