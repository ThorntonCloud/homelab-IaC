# Talos Kubernetes Cluster

This project provides Infrastructure as Code (IaC) for deploying a high-availability Talos Linux Kubernetes cluster on Proxmox VE using Terraform.

Base project and inspiration come from [Olav](https://olav.ninja/deploying-kubernetes-cluster-on-proxmox-part-1).

## Architecture

The cluster consists of:
- **3 Control Plane nodes** with VIP-based high availability
- **3 Worker nodes**
- **Virtual IP (VIP)** for control plane load balancing

All nodes run Talos Linux, an immutable and minimal Linux distribution designed for Kubernetes.

## Prerequisites

- Proxmox VE server with API access
- Terraform >= 1.13.3
- Network with available static IP addresses (7 total: 3 control planes + 3 workers + 1 VIP)
- Proxmox datastore configured and accessible

## Project Structure

```
Talos/
├── cluster.tf                  # Talos cluster configuration
├── files.tf                    # Talos image download
├── main.tf                     # Provider configuration
├── providers.tf                # Provider versions
├── variables.tf                # Variable declarations
├── virtual_machines.tf         # VM definitions
├── terraform.tfvars           # Your configuration (not in git)
├── terraform.tfvars.example   # Configuration template
├── templates/
│   └── cpnetwork.yaml.tmpl    # Network configuration patch
└── README.md
```

## Deployment Guide

### 1. Configure Terraform Variables

Copy the example variables file and configure it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your environment details:

```hcl
cluster_name              = "homelab"
proxmox_endpoint          = "https://YOUR_PROXMOX_IP:8006/"
default_gateway           = "10.10.209.254"
talos_cp_01_ip_addr       = "10.10.209.11"
talos_cp_02_ip_addr       = "10.10.209.12"
talos_cp_03_ip_addr       = "10.10.209.13"
talos_worker_01_ip_addr   = "10.10.209.15"
talos_worker_02_ip_addr   = "10.10.209.16"
talos_worker_03_ip_addr   = "10.10.209.17"
cp_vip                    = "10.10.209.10"
talos_version             = "v1.11.2"
kubernetes_version        = "1.34.0"
```

### Key Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `cluster_name` | Cluster identifier | homelab |
| `proxmox_endpoint` | Proxmox API endpoint | https://10.x.x.x:8006/ |
| `default_gateway` | Network gateway | 10.x.x.x |
| `talos_cp_0X_ip_addr` | Control plane node IPs (3 total) | 10.x.x.x |
| `talos_worker_0X_ip_addr` | Worker node IPs (3 total) | 10.x.x.x |
| `cp_vip` | Control plane virtual IP | 10.x.x.x |
| `talos_version` | Talos Linux version | v1.11.2 |
| `kubernetes_version` | Kubernetes version | 1.34.0 |

See `terraform.tfvars.example` for a complete template.

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the planned changes
terraform plan

# Apply the configuration
terraform apply
```

This will:
- Download the Talos Linux factory image to Proxmox
- Create 6 VMs (3 control planes, 3 workers)
- Configure networking with static IPs and VIP
- Bootstrap the Kubernetes cluster
- Generate talosconfig and kubeconfig files

The deployment process takes approximately 10-15 minutes.

### 3. Extract Cluster Credentials

After successful deployment, extract the configuration files:

```bash
# Extract kubeconfig
terraform output -raw kubeconfig > ~/.kube/config
chmod 600 ~/.kube/config

# Extract talosconfig
terraform output -raw talosconfig > ~/.talos/config
chmod 600 ~/.talos/config
```

### 4. Verify Cluster

Verify cluster health using Talos and Kubernetes tools:

```bash
# Check Talos cluster health
talosctl --talosconfig ~/.talos/config health

# View all nodes
kubectl get nodes

# View cluster info
kubectl cluster-info
```

Expected output:
```
NAME              STATUS   ROLES           AGE   VERSION
talos-cp-01       Ready    control-plane   5m    v1.34.0
talos-cp-02       Ready    control-plane   5m    v1.34.0
talos-cp-03       Ready    control-plane   5m    v1.34.0
talos-worker-01   Ready    <none>          4m    v1.34.0
talos-worker-02   Ready    <none>          4m    v1.34.0
talos-worker-03   Ready    <none>          4m    v1.34.0
```

## Using the Cluster

### Access with kubectl

The kubeconfig is automatically configured to use the VIP address for cluster access:

```bash
# Set your KUBECONFIG (if not using default location)
export KUBECONFIG=~/.kube/config

# View cluster resources
kubectl get all -A

# View cluster nodes with details
kubectl get nodes -o wide
```

### Access with talosctl

Use talosctl to interact with Talos-specific functionality:

```bash
# Check cluster health
talosctl health

# View service status on a node
talosctl --nodes 10.10.209.11 services

# Get Talos version
talosctl --nodes 10.10.209.11 version

# View node configuration
talosctl --nodes 10.10.209.11 get machineconfig
```

## Technical Details

### VM Specifications

**Control Plane Nodes:**
- CPU: 2 vCPU cores
- Memory: 4GB RAM
- Disk: 20GB
- IPs: 3 static IP addresses

**Worker Nodes:**
- CPU: 4 vCPU cores
- Memory: 4GB RAM
- Disk: 20GB
- IPs: 3 static IP addresses

**Additional:**
- Virtual IP: 1 IP address for HA control plane access

### Network Configuration

The cluster uses a custom network patch (`templates/cpnetwork.yaml.tmpl`) to configure:
- Static IP addresses for all nodes
- VIP assignment for control plane high availability
- Default gateway routing
- Network interface configuration

The VIP provides a single endpoint for accessing the Kubernetes API across all control plane nodes, enabling seamless failover.

### Terraform Providers

| Provider | Version | Purpose |
|----------|---------|---------|
| `bpg/proxmox` | 0.84.1 | Proxmox VE resource management |
| `siderolabs/talos` | 0.9.0 | Talos cluster configuration |
| `hashicorp/null` | latest | Null resource operations |

## Maintenance

### Upgrading Talos

To upgrade Talos Linux:

```bash
# Update talos_version in terraform.tfvars
talos_version = "v1.12.0"

# Apply changes
terraform plan
terraform apply
```

Talos will perform a rolling upgrade of the cluster.

### Upgrading Kubernetes

To upgrade Kubernetes:

```bash
# Update kubernetes_version in terraform.tfvars
kubernetes_version = "1.35.0"

# Apply changes
terraform plan
terraform apply
```

### Scaling Workers

1. Add new VM resources in `virtual_machines.tf`
2. Update `variables.tf` with new IP variables
3. Update `cluster.tf` to include new workers in machine secrets
4. Apply Terraform changes: `terraform apply`

### Extract credentials
terraform output -raw kubeconfig > ~/.kube/config
terraform output -raw talosconfig > ~/.talos/config
chmod 600 ~/.kube/config ~/.talos/config

### Accessing Node Console

Use talosctl to access the node console:

```bash
talosctl --nodes 10.10.209.11 dashboard
```

## Troubleshooting

### VMs not starting

```bash
# Check VM status in Proxmox web interface
# Or via Proxmox CLI:
qm status <VMID>
qm start <VMID>
```

### Nodes not joining cluster

```bash
# Check node bootstrap status
talosctl --nodes <NODE_IP> bootstrap

# View service logs
talosctl --nodes <NODE_IP> logs kubelet

# Check etcd health (control plane only)
talosctl --nodes <NODE_IP> etcd members
```

### VIP not accessible

```bash
# Verify VIP configuration
talosctl --nodes 10.10.209.11 get vips

# Check control plane node status
talosctl --nodes 10.10.209.11,10.10.209.12,10.10.209.13 health
```

### Cluster health issues

```bash
# Check overall cluster health
talosctl health --wait-timeout=5m

# View system services status
talosctl --nodes <NODE_IP> services

# Check for errors in dmesg
talosctl --nodes <NODE_IP> dmesg
```

### Regenerating Configuration

If you need to regenerate cluster configs:

```bash
# Destroy only the cluster configuration
terraform destroy -target=talos_machine_secrets.this

# Reapply
terraform apply
```

**Warning:** This will regenerate secrets and require re-bootstrapping the cluster.

## Backup and Recovery

### Backing Up etcd

```bash
# Create etcd snapshot
talosctl --nodes <CONTROL_PLANE_IP> etcd snapshot etcd-backup.db

# Download the snapshot
talosctl --nodes <CONTROL_PLANE_IP> copy /var/lib/etcd/etcd-backup.db ./etcd-backup.db
```

### Restoring from Backup

Refer to the [Talos etcd recovery documentation](https://www.talos.dev/latest/advanced/disaster-recovery/) for detailed recovery procedures.

## Cleanup

To completely remove the cluster:

```bash
# Destroy all Terraform-managed resources
terraform destroy

# Clean up local files
rm -f ~/.kube/config ~/.talos/config
```

## Additional Features

- **QEMU Guest Agent**: Enabled on all VMs for better management
- **Auto-start on boot**: All VMs configured to start automatically
- **Immutable infrastructure**: Talos provides an immutable OS with declarative configuration
- **Secure by default**: Minimal attack surface with no SSH access

## References

- [Talos Linux Documentation](https://www.talos.dev/)
- [Proxmox Terraform Provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
- [Talos Terraform Provider](https://registry.terraform.io/providers/siderolabs/talos/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Original Tutorial by Olav](https://olav.ninja/deploying-kubernetes-cluster-on-proxmox-part-1)

## License

This project is provided as-is for educational and operational purposes.