### Prerequisites

- Install [`Terraform`](https://www.terraform.io/intro/getting-started/install.html), version should be >=v0.10.0 (to check version execute: `$ terraform version`)

### Prepare a Cloud Foundry environment

1. Create a working directory: `$ mkdir my-cf-deployment-tf`, `$ cd my-cf-deployment-tf`
1. Clone repository: `$ git clone https://github.com/cloudfoundry-incubator/bosh-openstack-environment-templates.git repository`
1. Copy Terraform deployment files to working directory: `$ cp repository/cf-deployment-tf/* ./`
1. Install provider plugins: `$ terraform init`
1. `terraform-openstack-provider` version should be >=v0.2.2, (to upgrade execute: `$ terraform init -upgrade`)
1. Create Terraform variables file: `$ cp terraform.tfvars.template terraform.tfvars`
1. Adapt `terraform.tfvars` to your needs, notes:
   - the template uses Keystone V3
   - variable `bosh_router_id` is output of the previous BOSH terraform module.
1. Execute `$ terraform apply`

The terraform scripts will output the Cloud Foundry resource information required for the BOSH manifest.
Make sure to treat the created `terraform.tfstate` files with care.
