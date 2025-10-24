# RKE2 Kubernetes Cluster

This project provides Infrastructure as Code (IaC) for deploying a high-availability RKE2 Kubernetes cluster on Proxmox VE using Terraform and Ansible.

## Architecture

The cluster consists of:
- **3 Control Plane nodes** (rke2-cp-01, rke2-cp-02, rke2-cp-03)
- **3 Worker nodes** (rke2-worker-01, rke2-worker-02, rke2-worker-03)
- **1 HAProxy load balancer** (rke2-haproxy-01)

All nodes run Ubuntu Server (Noble/24.04 LTS by default).

## Prerequisites

- Proxmox VE server with API access
- Terraform >= 1.13.3
- Ansible with ansible-lint (optional)
- SSH key pair for VM access
- Network with available static IP addresses

## Project Structure

```
RKE2/
├── terraform/              # Infrastructure provisioning
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── files.tf
│   ├── virtual_machines.tf
│   └── terraform.tfvars   # Your configuration (not in git)
├── ansible/               # Configuration management
│   ├── install-rke2-cp.yaml
│   ├── update-upgrade.yaml
│   ├── verify-cluster.yaml
│   ├── inventory.yaml # Your inventory (not in git)
│   └── templates/
│       └── haproxy.cfg.tmpl
└── README.md
```

## Deployment Guide

### 1. Infrastructure Provisioning (Terraform)

#### Configure Terraform Variables

Copy the example variables file and configure it:

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your environment details:

```hcl
proxmox_endpoint            = "https://YOUR_PROXMOX_IP:8006/"
default_gateway             = "10.0.29.254"
ubuntu_cp_01_ip_addr        = "10.0.29.1"
ubuntu_cp_02_ip_addr        = "10.0.29.2"
ubuntu_cp_03_ip_addr        = "10.0.29.3"
ubuntu_worker_01_ip_addr    = "10.0.29.5"
ubuntu_worker_02_ip_addr    = "10.0.29.6"
ubuntu_worker_03_ip_addr    = "10.0.29.7"
ubuntu_haproxy_01_ip_addr   = "10.0.29.25"
ssh_key                     = "~/.ssh/id_ed25519.pub"
```

#### Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the planned changes
terraform plan

# Apply the configuration
terraform apply
```

This will:
- Download the Ubuntu cloud image to Proxmox
- Create 7 VMs (3 control planes, 3 workers, 1 HAProxy)
- Configure networking and SSH access

### 2. Cluster Configuration (Ansible)

#### Configure Ansible Inventory

Create `ansible/inventory.yaml` and match the hosts created by terraform. The jobs are split into groups (control-planes, workers, etc.)

```yaml
all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_private_key_file: ~/.ssh/id_ed25519
  hosts:
    haproxy-01:
      ansible_host: 10.10.209.25
    rke2-cp-01:
      ansible_host: 10.10.209.1
    # ... (rest of hosts)
```

#### Update and Upgrade Systems (Optional but Recommended)

```bash
cd ansible/
ansible-playbook -i inventory.yaml update-upgrade.yaml
```

If reboots are required, manually reboot the VMs and wait for them to come back online.

#### Deploy RKE2 Cluster

```bash
ansible-playbook -i inventory.yaml install-rke2-cp.yaml
```

This playbook will:
1. Install and configure HAProxy on the load balancer
2. Install RKE2 server on the primary control plane
3. Generate and distribute the cluster token
4. Install RKE2 server on and join secondary control planes to the cluster
5. Install RKE2 agent on and join worker nodes to the cluster
6. Fetch the kubeconfig file to `./.kube/config`

The installation takes approximately 5-20 minutes depending on network speed and specs of the VMs you deployed.

#### Verify Cluster

```bash
ansible-playbook -i inventory.yaml verify-cluster.yaml
```

Or use kubectl directly:

```bash
export KUBECONFIG=./.kube/config
kubectl get nodes
```

Expected output:
```
NAME             STATUS   ROLES                       AGE   VERSION
rke2-cp-01       Ready    control-plane,etcd,master   5m    v1.xx.x+rke2r1
rke2-cp-02       Ready    control-plane,etcd,master   4m    v1.xx.x+rke2r1
rke2-cp-03       Ready    control-plane,etcd,master   4m    v1.xx.x+rke2r1
rke2-worker-01   Ready    <none>                      3m    v1.xx.x+rke2r1
rke2-worker-02   Ready    <none>                      3m    v1.xx.x+rke2r1
rke2-worker-03   Ready    <none>                      3m    v1.xx.x+rke2r1
```

## Using the Cluster

### Access with kubectl

Set your KUBECONFIG environment variable:

```bash
export KUBECONFIG=/path/to/RKE2/ansible/.kube/config
```

Or copy to your default kubeconfig location:

```bash
mkdir -p ~/.kube
cp ansible/.kube/config ~/.kube/config
```

### Common kubectl Commands

```bash
# View cluster info
kubectl cluster-info

# View all nodes
kubectl get nodes -o wide

# View all pods across namespaces
kubectl get pods -A

# View cluster resources
kubectl top nodes
```

## Ansible Playbook Reference

### Selective Playbook Execution

The main installation playbook uses tags for selective execution:

```bash
# Only install HAProxy
ansible-playbook -i inventory.yaml install-rke2-cp.yaml --tags haproxy

# Only install control planes
ansible-playbook -i inventory.yaml install-rke2-cp.yaml --tags control-plane

# Only install workers
ansible-playbook -i inventory.yaml install-rke2-cp.yaml --tags workers

# Only fetch kubeconfig
ansible-playbook -i inventory.yaml install-rke2-cp.yaml --tags kubeconfig

# Skip HAProxy installation
ansible-playbook -i inventory.yaml install-rke2-cp.yaml --skip-tags haproxy
```

### Available Playbooks

| Playbook | Description |
|----------|-------------|
| `install-rke2-cp.yaml` | Full cluster installation (HAProxy + RKE2) |
| `update-upgrade.yaml` | Update and upgrade all Ubuntu hosts |
| `verify-cluster.yaml` | Verify cluster health and node status |

## Network Configuration

### HAProxy Load Balancer

The HAProxy node load balances the Kubernetes API across all control plane nodes:

- **Frontend**: Port 6443 (Kubernetes API)
- **Backend**: Control plane nodes on port 6443
- **Algorithm**: Round-robin

### Firewall Considerations

Ensure the following ports are accessible:

**Control Plane Nodes:**
- 6443/tcp - Kubernetes API
- 9345/tcp - RKE2 supervisor API
- 2379-2380/tcp - etcd client/peer
- 10250/tcp - kubelet metrics
- 30000-32767/tcp - NodePort Services

**Worker Nodes:**
- 10250/tcp - kubelet metrics
- 30000-32767/tcp - NodePort Services

**HAProxy Node:**
- 6443/tcp - Kubernetes API proxy

## Maintenance

### Updating the Cluster

To update packages on all nodes:

```bash
ansible-playbook -i inventory.yaml update-upgrade.yaml
```

### Scaling Workers

1. Add new VM resources in `terraform/virtual_machines.tf`
2. Update `terraform/variables.tf` with new IP variables
3. Apply Terraform changes: `terraform apply`
4. Add new workers to `ansible/inventory.yaml` under the `workers` group
5. Run the worker installation: `ansible-playbook -i inventory.yaml install-rke2-cp.yaml --tags workers`

### Backing Up etcd

```bash
# SSH to primary control plane
ssh ubuntu@10.10.209.1

# Create etcd snapshot
sudo /var/lib/rancher/rke2/bin/rke2 etcd-snapshot save --name manual-backup-$(date +%Y%m%d-%H%M%S)

# List snapshots
sudo ls -lh /var/lib/rancher/rke2/server/db/snapshots/
```

## Troubleshooting

### VMs not accessible via SSH

```bash
# Check VM status in Proxmox
# Verify cloud-init completed
ssh ubuntu@<VM_IP> 'cloud-init status'
```

### RKE2 installation hangs

The installation script can take 5-15 minutes per node. If it appears stuck:

```bash
# Check the installation process
ssh ubuntu@<VM_IP> 'ps aux | grep install'

# View system logs
ssh ubuntu@<VM_IP> 'sudo journalctl -f'
```

### Nodes not joining cluster

```bash
# Check RKE2 service status
ssh ubuntu@<VM_IP> 'sudo systemctl status rke2-server'
# or for workers:
ssh ubuntu@<VM_IP> 'sudo systemctl status rke2-agent'

# View RKE2 logs
ssh ubuntu@<VM_IP> 'sudo journalctl -u rke2-server -f'
```

### HAProxy not routing traffic

```bash
# Check HAProxy status
ssh ubuntu@10.10.209.25 'sudo systemctl status haproxy'

# Validate HAProxy config
ssh ubuntu@10.10.209.25 'sudo haproxy -c -f /etc/haproxy/haproxy.cfg'

# View HAProxy logs
ssh ubuntu@10.10.209.25 'sudo journalctl -u haproxy -f'
```

## Cleanup

To completely remove the cluster:

```bash
# Destroy Terraform-managed infrastructure
cd terraform/
terraform destroy

# Clean up local files
rm -f ansible/.kube/config
```

## References

- [RKE2 Documentation](https://docs.rke2.io/)
- [Proxmox Terraform Provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [HAProxy Documentation](https://www.haproxy.org/documentation.html)

## License

This project is provided as-is for educational and operational purposes.