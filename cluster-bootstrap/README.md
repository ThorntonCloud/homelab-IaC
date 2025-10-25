# Cluster Bootstrap

This directory contains Infrastructure as Code for bootstrapping Kubernetes clusters on Proxmox VE. Two distributions are supported, each with its own deployment methodology.

## Available Distributions

### [RKE2](RKE2/)
**Rancher Kubernetes Engine 2** - Security-focused Kubernetes distribution

- **Deployment Method**: Terraform (VMs) + Ansible (cluster configuration)
- **Management**: SSH-based via Ansible playbooks
- **Security**: CIS hardened, FIPS 140-2 compliance available
- **Best For**: Traditional operations teams, regulated environments

**Key Features:**
- SELinux support
- Built-in etcd snapshots
- Rancher management integration

[→ RKE2 Deployment Guide](RKE2/README.md)

---

### [Talos](Talos/)
**Talos Linux** - Immutable Kubernetes operating system

- **Deployment Method**: Terraform (VMs + cluster bootstrap)
- **Management**: API-only (talosctl), no SSH
- **Security**: Immutable OS, minimal attack surface
- **Best For**: Cloud-native teams, GitOps workflows

**Key Features:**
- API-managed lifecycle
- Built-in ArgoCD deployment
- Zero-touch production readiness
- Rolling updates and rollback

[→ Talos Deployment Guide](Talos/README.md)

## Architecture Comparison

| Aspect | RKE2 | Talos |
|--------|------|-------|
| **OS** | Any Linux distro | Talos Linux only |
| **Management** | SSH + Ansible | API (talosctl) |
| **Updates** | Playbook-driven | Declarative config |
| **Complexity** | Moderate | Low |
| **Flexibility** | High (traditional Linux) | Structured (API-driven) |
| **Security Model** | Hardened Linux | Immutable + minimal |
| **Bootstrap Time** | ~15-20 minutes | ~10-15 minutes |
| **Learning Curve** | Familiar (Linux/Ansible) | New (API-based) |

## Cluster Specifications

Both deployments create high-availability clusters with identical resource footprints:

### Node Configuration

**Control Plane Nodes (3):**
- CPU: 2 vCPU cores
- Memory: 4GB RAM
- Disk: 20GB
- Role: Kubernetes control plane (etcd, API server, scheduler, controller-manager)

**Worker Nodes (3):**
- CPU: 4 vCPU cores
- Memory: 4GB RAM
- Disk: 20GB
- Role: Application workload execution

**Virtual IP:**
- 1 IP address for HA control plane access
- Provides single endpoint for API server across all control planes
- Enables seamless failover

### Network Requirements

Each deployment requires 7 static IP addresses:
- 3 for control plane nodes
- 3 for worker nodes
- 1 for Virtual IP (VIP)

Example IP scheme:
```
10.10.209.10  - VIP (control plane endpoint)
10.10.209.11  - Control Plane 01
10.10.209.12  - Control Plane 02
10.10.209.13  - Control Plane 03
10.10.209.15  - Worker 01
10.10.209.16  - Worker 02
10.10.209.17  - Worker 03
```

## Choosing a Distribution

### Choose RKE2 if you:

- ✅ Need maximum flexibility with Linux tooling
- ✅ Require compliance certifications (FIPS, CIS)
- ✅ Want to integrate with Rancher management
- ✅ Prefer familiar SSH-based operations
- ✅ Need to run custom kernel modules or system services
- ✅ Have existing Ansible automation

### Choose Talos if you:

- ✅ Want a modern, cloud-native approach
- ✅ Prefer API-driven, declarative management
- ✅ Value immutability and minimal attack surface
- ✅ Plan to use GitOps workflows extensively
- ✅ Want faster, simpler cluster lifecycle management
- ✅ Don't need SSH access to nodes

## Prerequisites

### Common Requirements

- **Proxmox VE**: Version 7.0 or higher with API access
- **Terraform**: Version 1.13.3 or higher
- **kubectl**: Latest version for cluster access
- **Network**: Available VLAN with DHCP or static IP range
- **Storage**: Proxmox datastore with sufficient space (minimum 120GB for 6 VMs)

### RKE2-Specific

- **Ansible**: Version 2.9 or higher
- **SSH Access**: Ability to SSH into created VMs
- **Load Balancer**: HAProxy or equivalent (can be deployed on separate VM)

### Talos-Specific

- **talosctl**: Talos CLI for cluster management
- **No SSH required**: All management via API

## General Deployment Workflow

Both distributions follow a similar high-level workflow:

### 1. Prepare Configuration

```bash
# Clone repository
git clone <your-repo>
cd cluster-bootstrap/<RKE2|Talos>

# Copy example configuration
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit with your environment details
vim terraform/terraform.tfvars
```

### 2. Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Validate Terraform configurations
terraform validate

# Review planned changes
terraform plan

# Deploy infrastructure
terraform apply
```

### 3. Configure Cluster

**For RKE2:**
```bash
cd ../ansible

# Update inventory with your IPs
vim inventory.yaml

# Deploy RKE2
ansible-playbook -i inventory.yaml install-rke2-cp.yaml

# Extract kubeconfig
scp <control-plane-ip>:/etc/rancher/rke2/rke2.yaml ~/.kube/config
```

**For Talos:**
```bash
# Credentials are automatically generated
terraform output -raw kubeconfig > ~/.kube/config
terraform output -raw talosconfig > ~/.talos/config
```

### 4. Verify Cluster

```bash
# Check node status
kubectl get nodes

# View all resources
kubectl get all -A

# Check cluster info
kubectl cluster-info
```

### 5. Deploy GitOps (Optional but Recommended)

**For RKE2:**
Deploy ArgoCD manually or via Helm. ArgoCD deployment can be customized to deploy on RKE2.

**For Talos:**
ArgoCD deployment included in the Talos directory with separate Terraform deployment.

```bash
cd ../argocd/terraform
terraform init
terraform apply
```

## Post-Deployment Steps

### 1. Configure kubectl Context

```bash
# Set default context
kubectl config use-context <cluster-name>

# Verify access
kubectl get nodes
```

### 2. Deploy Infrastructure Components

```bash
# Return to repository root
cd ../../../

# Deploy core infrastructure via ArgoCD
kubectl apply -f infrastructure/root-app.yaml

# Verify deployment
kubectl get applications -n argocd
```

### 3. Access Cluster Services

```bash
# Get cluster endpoint
kubectl cluster-info

# For RKE2: Use load balancer IP or control plane IP
# For Talos: Use VIP address
```

## Maintenance Operations

### Cluster Upgrades

**RKE2:**
```bash
cd cluster-bootstrap/RKE2/ansible

# Update RKE2 version in vars
nano install-rke2-cp.yaml

# Run upgrade playbook
ansible-playbook -i inventory.yaml install-rke2-cp.yaml
```

**Talos:**
```bash
cd cluster-bootstrap/Talos/terraform

# Update versions in terraform.tfvars
nano terraform.tfvars

# Apply changes (rolling update)
terraform apply
```

### Adding Worker Nodes

**RKE2:**
1. Create new VMs via Terraform
2. Add to Ansible inventory
3. Run worker deployment playbook

**Talos:**
1. Add VM definitions in `virtual_machines.tf`
2. Update `variables.tf` with new IPs
3. Run `terraform apply`

### Scaling Control Plane

Both distributions support scaling to 5 or 7 control plane nodes for higher availability. However, 3 nodes provide sufficient HA for most homelab scenarios.

## Backup and Recovery

### Configuration Backup

All cluster configurations are stored in Git:
- Terraform state (store remotely recommended)
- Ansible playbooks and inventory
- Talos machine configurations

### etcd Backup

**RKE2:**
```bash
# Automated snapshots configured by default
# Manual snapshot:
ssh <control-plane-node>
sudo /var/lib/rancher/rke2/bin/etcd-snapshot save
```

**Talos:**
```bash
# Create snapshot
talosctl --nodes <control-plane-ip> etcd snapshot etcd-backup.db

# Download snapshot
talosctl --nodes <control-plane-ip> copy /var/lib/etcd/etcd-backup.db ./
```

### Disaster Recovery

Both distributions support etcd restoration from snapshots. Refer to respective documentation:
- [RKE2 Backup & Restore](https://docs.rke2.io/datastore/backup_restore)
- [Talos Disaster Recovery](https://www.talos.dev/latest/advanced/disaster-recovery/)

## Troubleshooting

### Common Issues

#### VMs Not Starting

```bash
# Check Proxmox VM status
qm status <VMID>

# Start VM manually
qm start <VMID>

# Check VM console
qm terminal <VMID>
```

#### Network Connectivity Issues

```bash
# Verify IP configuration
# RKE2: SSH to node and check
ip addr show

# Talos: Use talosctl
talosctl --nodes <ip> get addresses

# Test connectivity
ping <gateway>
ping <other-nodes>
```

#### Cluster Not Bootstrapping

**RKE2:**
```bash
# Check RKE2 service status
ssh <control-plane-node>
sudo systemctl status rke2-server

# View logs
sudo journalctl -u rke2-server -f
```

**Talos:**
```bash
# Check bootstrap status
talosctl --nodes <control-plane-ip> bootstrap

# View service logs
talosctl --nodes <control-plane-ip> logs kubelet
talosctl --nodes <control-plane-ip> logs etcd
```

#### Control Plane VIP Not Accessible

```bash
# Check VIP configuration
# RKE2: Verify HAProxy or load balancer
curl -k https://<vip>:6443

# Talos: Check VIP status
talosctl --nodes <control-plane-ip> get vips
```

### Getting Help

1. Check the specific distribution README
2. Review Terraform and Ansible logs
3. Consult official documentation:
   - [RKE2 Docs](https://docs.rke2.io/)
   - [Talos Docs](https://www.talos.dev/)

## Migration Between Distributions

While both distributions run standard Kubernetes, migrating between them requires:

1. **Deploy new cluster** with target distribution
2. **Backup workloads** from source cluster
3. **Restore workloads** to target cluster
4. **Update DNS/Load balancers** to point to new cluster
5. **Decommission old cluster**

Tools like [Velero](https://velero.io/) can assist with workload migration.

## Performance Considerations

### Resource Allocation

The default configuration provides:
- **Total vCPU**: 18 cores (6 control plane + 12 worker)
- **Total Memory**: 24GB (12GB control plane + 12GB worker)
- **Total Storage**: 120GB (20GB per node)

Adjust based on your workload requirements:

```hcl
# In terraform/variables.tf or terraform.tfvars
worker_cpu    = 6  # Increase for CPU-intensive workloads
worker_memory = 8  # Increase for memory-intensive workloads
worker_disk   = 50 # Increase for storage-intensive workloads
```

### Network Performance

- **Control Plane**: Low network overhead (mainly API requests)
- **Workers**: High network overhead (pod-to-pod, ingress)

### Storage Performance

- **Default**: Proxmox local storage (SSD recommended)
- **Upgrade options**: NVMe, distributed storage (Ceph)
- **For high IOPS**: Dedicated NVMe storage to worker nodes

## Security Best Practices

### Network Segmentation

- Place cluster nodes on dedicated VLAN
- Restrict access to Proxmox API
- Use firewall rules to limit node-to-node traffic

### Access Control

- Use strong passwords/keys for Proxmox
- Implement RBAC in Kubernetes
- Rotate credentials regularly

### Secrets Management

- Never commit sensitive data to Git
- Use `.gitignore` for `terraform.tfvars`
- Consider external secrets management (Vault, sealed-secrets)

### Monitoring

- Enable Prometheus metrics
- Set up alerting for cluster health
- Monitor resource usage

## Next Steps

After deploying your cluster:

1. **Deploy infrastructure components** from `infrastructure/`
2. **Set up monitoring** (Prometheus, Grafana)
3. **Configure backups** (Velero, etcd snapshots)
4. **Deploy applications** via ArgoCD
5. **Implement security policies** (Network Policies, Pod Security)

## Related Documentation

- [Root README](../README.md) - Repository overview
- [RKE2 README](RKE2/README.md) - RKE2-specific documentation
- [Talos README](Talos/README.md) - Talos-specific documentation
- [Infrastructure README](../infrastructure/README.md) - Core components