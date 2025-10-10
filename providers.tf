terraform {
  required_version = ">= 1.13.3"
  
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
        version = "0.84.1"
    }
    talos = {
      source = "siderolabs/talos"
      version = "0.9.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}