# Talos Kubernetes Cluster

This project provides Infrastructure as Code (IaC) for deploying a high-availability Talos Linux Kubernetes cluster on Proxmox VE using Terraform, with GitOps capabilities via ArgoCD.

Base project and inspiration come from [Olav](https://olav.ninja/deploying-kubernetes-cluster-on-proxmox-part-1).

## Architecture

The cluster consists of:
- **3 Control Plane nodes** with VIP-based high availability
- **3 Worker nodes**
- **Virtual IP (VIP)** for control plane load balancing
- **Cilium** for CNI and Load Balancing
- **ArgoCD** for GitOps-based application deployment

All nodes run Talos Linux, an immutable and minimal Linux distribution designed for Kubernetes.

## Project Structure

```
Talos/
├── terraform/                  # Phase 1: Cluster Infrastructure
│   ├── cluster.tf              # Talos cluster configuration
│   ├── files.tf                # Talos image download
│   ├── main.tf                 # Provider configuration
│   ├── providers.tf            # Provider versions
│   ├── variables.tf            # Variable declarations
│   └── virtual_machines.tf     # VM definitions
├── cilium/                     # Phase 2: Networking (CNI + Gateway API)
│   ├── main.tf                 # Cilium & CRD installation
│   └── variables.tf            # Configuration
├── argocd/                     # Phase 3: GitOps
│   └── terraform/              # ArgoCD deployment
└── README.md
```

## Prerequisites

- Proxmox VE server with API access
- Terraform >= 1.13.3
- Network with available static IP addresses (7 total: 3 control planes + 3 workers + 1 VIP)
- Proxmox datastore configured and accessible

# Deployment Guide

The deployment is split into three distinct phases to ensure proper dependency management and avoid race conditions.

## Phase 1: Deploy Cluster Infrastructure

This phase provisions the Proxmox VMs and bootstraps the minimal Talos cluster.

### 1. Configure Terraform Variables

Navigate to the terraform directory:
```bash
cd terraform
```

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

## Phase 2: Deploy Networking (Cilium)

This phase installs the Cilium CNI and Gateway API CRDs. This is a separate step because it requires the cluster API to be fully available.

### 1. Deploy Cilium

Navigate to the cilium directory:
```bash
cd ../cilium
```

Apply the configuration:

```bash
terraform init
terraform apply
```

This will:
- Install Gateway API CRDs (v1.2.0)
- Install Cilium Helm chart (v1.18.0)
- Configure Cilium as the CNI and kube-proxy replacement

### 2. Verify Cluster Health

Now that the CNI is installed, nodes should become Ready.

```bash
# Check Talos cluster health
talosctl --talosconfig ~/.talos/config health

# View all nodes
kubectl get nodes

# Check Cilium pods
kubectl -n kube-system get pods -l k8s-app=cilium
```

## Phase 3: Deploy ArgoCD
Once the cluster is running and healthy, deploy ArgoCD to enable GitOps workflows.

### 1. Review ArgoCD Configuration
The `argocd/values.yaml` file contains the Helm chart configuration. Review and customize as needed:
```bash
cd ../argocd
cat values.yaml
```

### Deploy ArgoCD via Terraform
```bash
cd terraform

# Initialize Terraform with Kubernetes provider
terraform init

# Review ArgoCD deployment plan
terraform plan

# Deploy ArgoCD
terraform apply
```

This will:

Create the argocd namespace
Deploy ArgoCD using the official Helm chart
Configure ArgoCD with your custom values

### 3. Access ArgoCD UI
```bash
# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Port forward to access the UI
# Port forward to access the UI
kubectl port-forward svc/argocd-server -n argocd 8080:443 # Optional - LoadBalancer will have an external IP once Cilium L2 Announcement is configured

# Access at: https://localhost:8080
# Username: admin
# Password: (from command above)
```

### 4. Configure ArgoCD CLI (optional)
```bash
# Arch Linux
pacman -s argocd

# curl
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# homebrew
brew install argocd
# or download from: https://argo-cd.readthedocs.io/en/stable/cli_installation/

# Login to ArgoCD
argocd login localhost:8080 --username admin --password <password>

# Change admin password
argocd account update-password
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

# Deploy Applications with ArgoCD
ArgoCD enables GitOps-based application deployment. Applications are defined in Git and automatically synchronized to the cluster.

```bash
# Create an application via CLI
argocd app create my-app \
  --repo https://github.com/your-org/your-repo \
  --path manifests \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Or apply via YAML
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-repo
    targetRevision: HEAD
    path: manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# View applications
argocd app list

# Sync an application
argocd app sync my-app
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
| `hashicorp/helm` | latest | Helm chart deployment |
| `hashicorp/kubernetes` | latest | Kubernetes resource management |

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

### Upgrading ArgoCD
```bash
cd argocd/terraform

# Update version in argocd.tf or values.yaml
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

## ArgoCD Issues

### ArgoCD not deploying
```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# View ArgoCD logs
kubectl logs -n argocd deployment/argocd-server

# Check ArgoCD application status
kubectl get applications -n argocd
argocd app get <app-name>
```

### Application sync failures
```bash
# View application sync status
argocd app get <app-name>

# View detailed sync logs
argocd app logs <app-name>

# Force sync
argocd app sync <app-name> --force
```

### Reset admin password
```bash
# Delete the initial admin secret
kubectl -n argocd delete secret argocd-initial-admin-secret

# Get new password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

## Backup and Recovery

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

- **Auto-start on boot**: All VMs configured to start automatically
- **Immutable infrastructure**: Talos provides an immutable OS with declarative configuration
- **Secure by default**: Minimal attack surface with no SSH access
- **GitOps workflow**: ArgoCD enables declarative, Git-based application management

## References

- [Talos Linux Documentation](https://www.talos.dev/)
- [Proxmox Terraform Provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
- [Talos Terraform Provider](https://registry.terraform.io/providers/siderolabs/talos/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Cilium Documentation](https://docs.cilium.io/)
- [Original Tutorial by Olav](https://olav.ninja/deploying-kubernetes-cluster-on-proxmox-part-1)
