# Talos/bootstrap/terraform/main.tf
terraform {
  required_version = ">= 1.13.3"

  cloud {
    organization = "ThorntonCloud"
    workspaces {
      name = "talos-bootstrap" # Different workspace!
    }
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38.0"
    }
  }
}

# This workspace expects kubeconfig to exist
provider "helm" {
  kubernetes = {
    config_path = pathexpand("/tmp/kubeconfig")
  }
}

provider "kubernetes" {
  config_path = pathexpand("/tmp/kubeconfig")
}