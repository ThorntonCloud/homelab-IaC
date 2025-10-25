# Homelab Infrastructure as Code

This repository contains Infrastructure as Code (IaC) for deploying and managing a production-ready Kubernetes homelab environment with GitOps-based automation.

## Overview

A complete Kubernetes platform with automated deployment, built-in CI/CD, and infrastructure management:

- **Kubernetes Clusters**: RKE2 and Talos Linux distributions
- **GitOps**: ArgoCD for declarative application management
- **CI/CD**: GitHub Actions with self-hosted runners in-cluster
- **Core Infrastructure**: Storage, networking, and certificate management

## Repository Structure

```
.
├── cluster-bootstrap/          # Kubernetes cluster deployment
│   ├── RKE2/                  # RKE2 cluster (Terraform + Ansible)
│   └── Talos/                 # Talos Linux cluster (Terraform + ArgoCD)
│       ├── terraform/         # Cluster infrastructure
│       └── argocd/           # GitOps setup
├── infrastructure/            # Core infrastructure applications
│   ├── cert-manager/         # TLS certificate management
│   ├── metallb/              # Bare-metal load balancer
│   ├── openebs/              # Cloud-native storage
│   └── root-app.yaml         # ArgoCD App-of-Apps
└── .github/workflows/        # CI/CD automation
```

## Quick Start

### 1. Deploy Cluster
Right now, the initial cluster deployment is a bit manual in order to setup the GitHub Runner controller and scale set. I may redo this at some point using Cluster API or similar tools. The management cluster deployment would still be somewhat manual, but then the application clusters could be 100% automated.

Currently configured for Talos Linux with full automation support:

```bash
cd cluster-bootstrap/Talos/terraform
terraform init
terraform apply
```

Extract credentials:
```bash
terraform output -raw kubeconfig > ~/.kube/config
terraform output -raw talosconfig > ~/.talos/config
chmod 600 ~/.kube/config ~/.talos/config
```

See [Talos README](cluster-bootstrap/Talos/README.md) for detailed deployment guide.

### 2. Deploy ArgoCD

Enable GitOps-based infrastructure management:

```bash
cd ../argocd/terraform
terraform init
terraform apply
```

Access ArgoCD UI:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

kubectl port-forward svc/argocd-server -n argocd 8080:443 # optional -will pick up an external IP automatically once Metallb is deployed

# Visit: https://localhost:8080
```

### 3. Set Up GitHub Actions Runners

For CI/CD automation with self-hosted runners:

**Install Actions Runner Controller:**
```bash
NAMESPACE="arc-systems"
helm install arc \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
```

**Install Runner Scale Set:**
```bash
INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/<username>/<repo>"
GITHUB_PAT="<PAT>"
helm install "${INSTALLATION_NAME}" \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
    --set githubConfigSecret.github_token="${GITHUB_PAT}" \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```

**Verify:**
```bash
kubectl get pods -n arc-systems

# Expected output:
NAME                                     READY   STATUS    RESTARTS   AGE
arc-gha-rs-controller-55558fffc7-bqjgg   1/1     Running   0          4h2m
arc-runner-set-754b578d-listener         1/1     Running   0          4h1m
```

### 4. (Optional) Trigger GitHub Actions
- The `deploy-cluster.yaml` will run on pushes to the Talos terraform directory (or mannually) and use the new in-cluster runners to run terraform apply. It also checks formatting and validates the terraform module. Currently assumes Terraform state is stored in HCP Terraform.
- The `bootstrap-cluster.yaml` is triggered when `deploy-cluster.yaml` completes successfully and deploys ArgoCD and the `root-app.yaml` base Argo app. The latter uses `null_resource`, so it only runs the first time unless you destroy the terraform object (`terraform destroy -target null_resource.argocd_bootstrap`)

## Architecture

### Cluster Specifications

**Control Plane (3 nodes):**
- 2 vCPU, 4GB RAM, 20GB disk each
- High availability with VIP-based failover

**Workers (3 nodes):**
- 4 vCPU, 4GB RAM, 20GB disk each
- Application workload execution

**Networking:**
- 7 static IPs (3 control plane + 3 workers + 1 VIP)
- MetalLB for LoadBalancer services

### Core Components

| Component | Purpose | Namespace |
|-----------|---------|-----------|
| **ArgoCD** | GitOps continuous delivery | argocd |
| **cert-manager** | TLS certificate automation | cert-manager |
| **MetalLB** | Load balancer for bare-metal | metallb-system |
| **OpenEBS** | Persistent storage | openebs |
| **ARC** | GitHub Actions runners | arc-systems, arc-runners |

## Kubernetes Distributions

### Talos Linux (Primary)

✅ Fully configured with automation
- Terraform-based deployment
- ArgoCD integration
- GitHub Actions workflows
- API-managed, immutable OS

[→ Talos Documentation](cluster-bootstrap/Talos/README.md)

### RKE2 (Alternative)

⚠️ Manual deployment only
- Terraform + Ansible
- Security-focused distribution
- Traditional Linux approach

[→ RKE2 Documentation](cluster-bootstrap/RKE2/README.md)

## GitOps Workflow

All infrastructure and applications are managed declaratively through Git:

1. **Make changes** in Git repository
2. **Commit and push** changes
3. **ArgoCD automatically syncs** to cluster
4. **GitHub Actions** run tests and validations

```bash
# View all applications
kubectl get applications -n argocd

# Check sync status
argocd app list
```

## CI/CD Integration

GitHub Actions workflows automatically:
- Validate Terraform configurations
- Test Kubernetes manifests (WIP)
- Deploy infrastructure changes
- Run on self-hosted runners in the cluster

Workflows are located in `.github/workflows/` (configured for Talos cluster).

## Prerequisites

- **Proxmox VE** with API access
- **Terraform** >= 1.13.3
- **kubectl**
- **7+ static IP addresses** on your network
- **GitHub account** (for Actions and ArgoCD integration)

### Optional Tools

- **talosctl** - For Talos cluster management
- **ArgoCD CLI** - For GitOps operations
- **Helm** - For Actions Runner

## Project Status

| Feature | Status |
|---------|--------|
| Talos Cluster Deployment | ✅ Production Ready |
| ArgoCD GitOps | ✅ Production Ready |
| Infrastructure Components | ✅ Production Ready |
| GitHub Actions Integration | ✅ Production Ready |
| RKE2 Cluster Deployment | ⚠️ Manual Only |
| Test Kubernetes manifests | ☐ Work-in-progress |
| Additional applications | ☐ Work-in-progress |

## Documentation

- **[Cluster Bootstrap Guide](cluster-bootstrap/README.md)** - Deploy Kubernetes clusters
- **[Talos Deployment](cluster-bootstrap/Talos/README.md)** - Talos-specific documentation
- **[RKE2 Deployment](cluster-bootstrap/RKE2/README.md)** - RKE2-specific documentation
- **[Infrastructure Components](infrastructure/README.md)** - Core platform services

## Security

- **Immutable infrastructure** via Talos Linux
- **GitOps principles** - all changes tracked in Git
- **Secrets management** - `.tfvars` files excluded from Git, secrets stored in GitHub Secrets. May use something like Vault in the future.
- **API-only access** - no SSH to Talos nodes
- **Automated TLS** - cert-manager for all