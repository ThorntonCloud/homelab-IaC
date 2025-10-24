terraform {
  required_version = ">= 1.13.3"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.84.1"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
  }
}