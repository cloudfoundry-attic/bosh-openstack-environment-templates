### Prepare an OpenStack environment

Prerequisite: Install [terraform](https://www.terraform.io/intro/getting-started/install.html)

1. Clone `git clone https://github.com/cloudfoundry-incubator/bosh-openstack-environment-templates.git`
1. Create a working directory
1. Copy `bosh-init-tf/terraform.tfvars.template` to `<working-directory>/terraform.tfvars`
1. Execute `bosh-init-tf/generate_ssh_keypair.sh` to generate a key pair.
1. Move the generated key pairs to `<working-directory>`
1. Navigate to `<working-directory>`
    1. Configure `terraform.tfvars`
    1. Execute `terraform apply <cloned-repo-path>/bosh-init-tf`

The terraform scripts will output the OpenStack resource information required for the BOSH manifest.
Make sure to treat the created `terraform.tfstate` files with care.

### Delete the OpenStack environment

If you have the `terraform.tfstate` file available `destroy_openstack_env.sh` will
destroy the created resources.

*NOTE:* The template uses Keystone V3
