# Talos Kubernetes Cluster on Proxmox

Terraform configuration for deploying a highly available Talos Linux Kubernetes cluster on Proxmox VE.

## Architecture

- **Control Plane**: 3 nodes with VIP-based HA
- **Worker Nodes**: 3 nodes
- **Networking**: `/16` subnet with static IP assignments
- **Storage**: ProxStorage datastore

## Infrastructure

### Control Plane Nodes
- 2 vCPU cores, 4GB RAM, 20GB disk each
- IPs: `10.10.210.1-3`
- Virtual IP: `10.10.210.210`

### Worker Nodes
- 4 vCPU cores, 4GB RAM, 20GB disk each
- IPs: `10.10.210.5-7`

## Prerequisites

- Proxmox VE cluster accessible at `10.10.200.1:8006`
- Terraform >= 1.13.3
- Network gateway at `10.10.10.1`
- ProxStorage datastore configured

## Providers

- `bpg/proxmox` v0.84.1
- `siderolabs/talos` v0.9.0

## Deployment

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy cluster
terraform apply

# Extract credentials
terraform output -raw kubeconfig > ~/.kube/config
terraform output -raw talosconfig > ~/.talos/config
chmod 600 ~/.kube/config ~/.talos/config
```

## Configuration

Default values are defined in `variables.tf`. Override as needed:

```bash
terraform apply -var="kubernetes_version=1.35.0" -var="cluster_name=production"
```

## Key Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `cluster_name` | homelab | Cluster identifier |
| `talos_version` | v1.11.2 | Talos Linux version |
| `kubernetes_version` | 1.34.0 | Kubernetes version |
| `cp_vip` | 10.10.210.210 | Control plane VIP |

## Network Configuration

The cluster uses a custom network patch (`cpnetwork.yaml.tmpl`) to configure:
- Static IP addresses
- VIP assignment for control plane HA
- Default gateway routing

## Post-Deployment

After successful deployment, verify cluster health:

```bash
talosctl --talosconfig ~/.talos/config health
kubectl get nodes
```

## Notes

- Talos images are automatically downloaded from factory.talos.dev
- The bootstrap process runs on the first control plane node
- All VMs are configured to start on boot
- QEMU guest agent is enabled for better VM management