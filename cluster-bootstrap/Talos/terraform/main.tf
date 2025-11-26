# Proxmox Provider Configuration
#
# Configures the connection to the Proxmox VE API.
# This provider is used to provision the VMs that will host the Talos cluster.
#
# Credentials are passed via variables, which should be sourced from
# environment variables or a secure `terraform.tfvars` file (not committed to git).

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  
  # We allow insecure connections (self-signed certs) for the local Proxmox instance.
  insecure  = true
  
  api_token = var.api_token

  ssh {
    username = var.proxmox_user
    password = var.proxmox_pass
  }
}