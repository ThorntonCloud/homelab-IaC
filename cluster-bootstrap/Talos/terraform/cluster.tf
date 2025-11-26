# Talos Cluster Configuration
#
# This file defines the core logic for bootstrapping the Talos cluster.
# It handles:
# 1. Generating machine secrets.
# 2. Generating machine configurations for Control Plane and Worker nodes.
# 3. Applying configurations to the nodes.
# 4. Bootstrapping the cluster (etcd).
# 5. Retrieving the kubeconfig.

# Talos Machine Secrets
# Generates the secrets required for the cluster (CA keys, tokens, etc.).
resource "talos_machine_secrets" "machine_secrets" {}

# Talos Client Configuration
# Generates the client configuration (talosconfig) for interacting with the cluster via talosctl.
data "talos_client_configuration" "talosconfig" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoints            = [var.cp_vip]
}

# Control Plane Machine Configurations
# Generates the machine configuration for the Control Plane nodes.
# We use separate data sources for each node to allow for potential node-specific customization if needed,
# although currently they share the same base configuration.
data "talos_machine_configuration" "machineconfig_cp" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.cp_vip}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
}

data "talos_machine_configuration" "machineconfig_cp_02" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${var.cp_vip}:6443"
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.machine_secrets.machine_secrets
  kubernetes_version = var.kubernetes_version
}

data "talos_machine_configuration" "machineconfig_cp_03" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${var.cp_vip}:6443"
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.machine_secrets.machine_secrets
  kubernetes_version = var.kubernetes_version
}

# Apply Control Plane Configurations
# Applies the generated configuration to the Control Plane nodes.
#
# CRITICAL CONFIGURATION:
# We apply two key patches here:
# 1. cpnetwork.yaml.tmpl: Configures the static IP and VIP for the node.
# 2. disable-cni.yaml.tmpl: Disables the default Flannel CNI and kube-proxy.
#    This is REQUIRED for Cilium to function correctly as the CNI and kube-proxy replacement.
resource "talos_machine_configuration_apply" "cp_config_apply" {
  depends_on                  = [proxmox_virtual_environment_vm.talos_cp_01]
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_cp.machine_configuration
  node                        = var.talos_cp_01_ip_addr
  config_patches = [
    templatefile("./templates/cpnetwork.yaml.tmpl", {
      cpip   = var.cp_vip,
      nodeip = var.talos_cp_01_ip_addr
      gw     = var.default_gateway
    }),
    templatefile("./templates/disable-cni.yaml.tmpl", {})
  ]
}

resource "talos_machine_configuration_apply" "cp_config_apply_02" {
  depends_on                  = [proxmox_virtual_environment_vm.talos_cp_02]
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_cp_02.machine_configuration
  node                        = var.talos_cp_02_ip_addr
  config_patches = [
    templatefile("./templates/cpnetwork.yaml.tmpl", {
      cpip   = var.cp_vip,
      nodeip = var.talos_cp_02_ip_addr
      gw     = var.default_gateway
    }),
    templatefile("./templates/disable-cni.yaml.tmpl", {})
  ]
}

resource "talos_machine_configuration_apply" "cp_config_apply_03" {
  depends_on                  = [proxmox_virtual_environment_vm.talos_cp_03]
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_cp_03.machine_configuration
  node                        = var.talos_cp_03_ip_addr
  config_patches = [
    templatefile("./templates/cpnetwork.yaml.tmpl", {
      cpip   = var.cp_vip,
      nodeip = var.talos_cp_03_ip_addr
      gw     = var.default_gateway
    }),
    templatefile("./templates/disable-cni.yaml.tmpl", {})
  ]
}

# Worker Machine Configurations
# Generates the machine configuration for the Worker nodes.
data "talos_machine_configuration" "machineconfig_worker" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.cp_vip}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
}

data "talos_machine_configuration" "machineconfig_worker_02" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.cp_vip}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
}

data "talos_machine_configuration" "machineconfig_worker_03" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.cp_vip}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
}

# Apply Worker Configurations
# Applies the generated configuration to the Worker nodes.
# Also includes the disable-cni patch for consistency and Cilium support.
resource "talos_machine_configuration_apply" "worker_config_apply" {
  depends_on                  = [proxmox_virtual_environment_vm.talos_worker_01]
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_worker.machine_configuration
  node                        = var.talos_worker_01_ip_addr
  config_patches = [
    templatefile("./templates/disable-cni.yaml.tmpl", {})
  ]
}

resource "talos_machine_configuration_apply" "worker_config_apply_02" {
  depends_on                  = [proxmox_virtual_environment_vm.talos_worker_02]
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_worker_02.machine_configuration
  node                        = var.talos_worker_02_ip_addr
  config_patches = [
    templatefile("./templates/disable-cni.yaml.tmpl", {})
  ]
}

resource "talos_machine_configuration_apply" "worker_config_apply_03" {
  depends_on                  = [proxmox_virtual_environment_vm.talos_worker_03]
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_worker_03.machine_configuration
  node                        = var.talos_worker_03_ip_addr
  config_patches = [
    templatefile("./templates/disable-cni.yaml.tmpl", {})
  ]
}

# Bootstrap Control Plane
# Bootstraps the cluster on the first control plane node.
# This initializes etcd and the Kubernetes control plane components.
resource "talos_machine_bootstrap" "bootstrap" {
  depends_on           = [talos_machine_configuration_apply.cp_config_apply]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = var.talos_cp_01_ip_addr
}

# Retrieve Kubeconfig
# Downloads the admin kubeconfig from the bootstrapped cluster.
resource "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on           = [talos_machine_bootstrap.bootstrap]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = var.talos_cp_01_ip_addr
}

# Outputs
output "talosconfig" {
  value     = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = resource.talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  sensitive = true
}

# External Kubeconfig
# Generates a kubeconfig that uses the VIP instead of the node IP.
# This is useful for accessing the cluster from outside the network or via a load balancer.
locals {
  kubeconfig_external = {
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = var.cluster_name
      cluster = {
        certificate-authority-data = talos_cluster_kubeconfig.kubeconfig.kubernetes_client_configuration.ca_certificate
        server                     = "https://${var.cp_vip}:6443"
      }
    }]
    contexts = [{
      name = var.cluster_name
      context = {
        cluster = var.cluster_name
        user    = "admin"
      }
    }]
    current-context = var.cluster_name
    users = [{
      name = "admin"
      user = {
        client-certificate-data = talos_cluster_kubeconfig.kubeconfig.kubernetes_client_configuration.client_certificate
        client-key-data         = talos_cluster_kubeconfig.kubeconfig.kubernetes_client_configuration.client_key
      }
    }]
  }
}

output "kubeconfig_external" {
  description = "Kubeconfig for external access (uses VIP instead of localhost)"
  sensitive   = true
  value       = yamlencode(local.kubeconfig_external)
}

# TODO: this needs to run after grabbing the kubeconfig
# Cluster Health Check - have to comment this out to get kubeconfig the first time.. 
# data "talos_cluster_health" "health" {
#   depends_on = [
#     talos_machine_configuration_apply.cp_config_apply,
#     talos_machine_configuration_apply.cp_config_apply_02,
#     talos_machine_configuration_apply.cp_config_apply_03,
#     talos_machine_configuration_apply.worker_config_apply,
#     talos_machine_configuration_apply.worker_config_apply_02,
#     talos_machine_configuration_apply.worker_config_apply_03
#   ]
#   client_configuration = data.talos_client_configuration.talosconfig.client_configuration
#   control_plane_nodes = [
#     var.talos_cp_01_ip_addr,
#     var.talos_cp_02_ip_addr,
#     var.talos_cp_03_ip_addr
#   ]
#   worker_nodes = [
#     var.talos_worker_01_ip_addr,
#     var.talos_worker_02_ip_addr,
#     var.talos_worker_03_ip_addr
#   ]
#   endpoints = [var.cp_vip]
# }