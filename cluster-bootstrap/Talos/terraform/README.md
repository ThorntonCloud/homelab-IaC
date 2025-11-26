# Talos Infrastructure Module

This Terraform module provisions the underlying infrastructure for the Talos Kubernetes cluster on Proxmox VE.

## Responsibilities

1.  **VM Provisioning**: Creates 3 Control Plane and 3 Worker VMs on Proxmox.
2.  **Image Management**: Downloads and uploads the Talos Linux ISO/Image to Proxmox storage.
3.  **Cluster Bootstrap**: Initializes the Talos cluster using `talos_machine_bootstrap`.
4.  **Configuration**: Generates and applies machine configurations (control plane, worker) with necessary patches.
5.  **Credentials**: Outputs the admin `kubeconfig` and `talosconfig`.

## Usage

```bash
terraform init
terraform apply
```

## Configuration

Configuration is handled via `terraform.tfvars`. Copy `terraform.tfvars.example` to get started.

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `proxmox_endpoint` | URL of your Proxmox API | - |
| `cluster_name` | Name of the cluster | - |
| `talos_version` | Version of Talos Linux to install | `v1.11.5` |
| `kubernetes_version` | Version of Kubernetes to install | `1.34.1` |
| `cp_vip` | Virtual IP for the Control Plane | - |
| `talos_cp_XX_ip_addr` | Static IPs for Control Plane nodes | - |
| `talos_worker_XX_ip_addr` | Static IPs for Worker nodes | - |

## Patches

This module applies specific patches to the Talos machine configuration:

-   **`disable-cni.yaml`**: Disables the default Flannel CNI and kube-proxy. This is **required** because we use Cilium (installed in the next phase) for CNI and kube-proxy replacement.
-   **`cpnetwork.yaml`**: Configures static networking and the VIP for control plane nodes.

## Outputs

| Output | Description | Sensitive |
|--------|-------------|-----------|
| `kubeconfig` | Admin kubeconfig for the cluster | Yes |
| `talosconfig` | Talos client configuration | Yes |
| `kubeconfig_external` | Kubeconfig using the VIP (for external access) | Yes |
