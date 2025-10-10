# Talos Kubernetes Cluster on Proxmox

Terraform configuration for deploying a highly available Talos Linux Kubernetes cluster on Proxmox VE.

Base project and inspiration come from [Olav](https://olav.ninja/deploying-kubernetes-cluster-on-proxmox-part-1).

## Architecture

- **Control Plane**: 3 nodes with VIP-based HA
- **Worker Nodes**: 3 nodes
- **Networking**: `/24` subnet with static IP assignments
- **Storage**: Proxmox datastore

## Infrastructure

### Control Plane Nodes
- 2 vCPU cores, 4GB RAM, 20GB disk each
- IPs: 3 IP addresses for the control plane nodes
- Virtual IP: 1 separate IP address for the control plane VIP

### Worker Nodes
- 4 vCPU cores, 4GB RAM, 20GB disk each
- IPs: 3 IP addresses for the worker nodes

## Prerequisites

- Proxmox VE cluster
- Terraform >= 1.13.3
- Proxmox datastore configured
- Network access to your Proxmox environment

## Project Structure

```
.
├── cluster.tf              # Talos cluster configuration
├── files.tf                # Talos image download
├── main.tf                 # Provider configuration
├── providers.tf            # Provider versions
├── variables.tf            # Variable declarations
├── virtual_machines.tf     # VM definitions
├── terraform.tfvars.example # Configuration template
├── terraform.tfvars        # Your actual values (gitignored)
└── templates/
    └── cpnetwork.yaml.tmpl # Network configuration patch
```

## Providers

- `bpg/proxmox` v0.84.1
- `siderolabs/talos` v0.9.0
- `hashicorp/null` - provider for specific use cases that intentionally does nothing

## Setup

```bash
# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your environment-specific values
vim terraform.tfvars
```

Update `terraform.tfvars` with your actual IP addresses, Proxmox endpoint, and other environment-specific settings.

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

All environment-specific values are configured in `terraform.tfvars` (not committed to version control). Variable declarations and defaults for non-sensitive values are in `variables.tf`.

## Key Variables

Configure these in `terraform.tfvars`:

| Variable | Description | Example |
|----------|-------------|---------|
| `cluster_name` | Cluster identifier | homelab |
| `proxmox_endpoint` | Proxmox API endpoint | https://10.x.x.x:8006/ |
| `default_gateway` | Network gateway | 10.x.x.x |
| `talos_cp_0X_ip_addr` | Control plane node IPs | 10.x.x.x |
| `talos_worker_0X_ip_addr` | Worker node IPs | 10.x.x.x |
| `cp_vip` | Control plane virtual IP | 10.x.x.x |
| `talos_version` | Talos Linux version | v1.11.2 |
| `kubernetes_version` | Kubernetes version | 1.34.0 |

See `terraform.tfvars.example` for a complete template.

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