provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  insecure  = true
  api_token = var.api_token

  username = var.proxmox_user
  password = var.proxmox_pass
}