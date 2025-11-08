# Proxmox VM via Terraform

Clones a VM from Cloud-Init template `ubuntu-24.04-ci` (VM 9000) and injects SSH key & DHCP.

## Usage
1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill values.
2. Run:
   terraform init
   terraform plan
   terraform apply
3. Destroy with:
   terraform destroy
