# Terraform Providers Configuration
#
# This configuration uses Terraform Cloud for state management.
#
# Required Providers:
# - proxmox: For managing VMs on the Proxmox cluster.
# - talos: For bootstrapping and configuring the Talos Linux nodes.
# - null: For utility resources (if needed).
terraform {
  required_version = ">= 1.13.3"

  cloud {
    organization = "ThorntonCloud"
    workspaces {
      name = "talos-cluster"
    }
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.87.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}