# Infrastructure Components

This directory contains core infrastructure components deployed on the Kubernetes cluster using ArgoCD's App-of-Apps pattern. These components provide essential platform capabilities for storage, networking, and security.

## Overview

The infrastructure is deployed declaratively via ArgoCD, following GitOps principles. All components are defined as Kubernetes manifests and automatically synchronized from this Git repository.

## Architecture

```
infrastructure/
├── root-app.yaml              # App-of-Apps: Manages all infrastructure apps
├── cert-manager/
│   └── app.yaml              # TLS certificate management
├── metallb/
│   ├── app.yaml              # Load balancer application
│   └── manifests/
│       └── metallb-native.yaml  # MetalLB configuration
└── openebs/
    ├── app.yaml              # Storage operator application
    └── manifests/
        ├── openebs-operator-lite.yaml  # OpenEBS deployment
        └── openebs-lite-sc.yaml        # Storage classes
```

## Deployment

### Initial Setup

After bootstrapping your Kubernetes cluster, deploy all infrastructure components using the App-of-Apps pattern:

```bash
# Ensure ArgoCD is running
kubectl get pods -n argocd

# Deploy root application (deploys all infrastructure)
kubectl apply -f infrastructure/root-app.yaml

# Wait for applications to sync
argocd app list

# Verify all components are healthy
kubectl get applications -n argocd
```

This single command deploys and manages:
- cert-manager
- MetalLB
- OpenEBS
- Any other apps I add to the infrastructure directory

### ArgoCD App-of-Apps Pattern

The `root-app.yaml` implements the App-of-Apps pattern, where a parent ArgoCD application manages multiple child applications. This provides:

- **Single source of truth**: All infrastructure defined in Git
- **Consistent deployment**: All components deployed the same way
- **Easy management**: Add/remove components by updating Git
- **Automatic sync**: ArgoCD keeps cluster state in sync with Git

## Components

### cert-manager

**Purpose**: Automated TLS certificate management and issuance

**Namespace**: `cert-manager`

**Features**:
- Automatic certificate issuance and renewal
- Let's Encrypt integration (ACME protocol)
- Self-signed certificates for development
- Certificate rotation before expiry

**Usage**:

```yaml
# Example: Request a certificate
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-com-tls
  namespace: default
spec:
  secretName: example-com-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - example.com
    - www.example.com
```

**Configuration**:

```bash
# View cert-manager pods
kubectl get pods -n cert-manager

# Check certificate status
kubectl get certificates -A

# View certificate details
kubectl describe certificate <cert-name> -n <namespace>
```

**Common Tasks**:

```bash
# Create ClusterIssuer for Let's Encrypt
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

# Check issuer status
kubectl get clusterissuer
```

---

### MetalLB

**Purpose**: Load balancer implementation for bare-metal / private cloud Kubernetes clusters

**Namespace**: `metallb-system`

**Features**:
- LoadBalancer service type support
- Layer 2 (ARP) and BGP modes
- IP address pool management
- Automatic IP assignment

**Configuration**:

The `manifests/metallb-native.yaml` file contains the MetalLB configuration including IP address pools and L2 advertisements.

**Example Configuration**:

```yaml
# IP Address Pool
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.10.209.100-10.10.209.150  # Adjust to your network

---
# L2 Advertisement
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default-pool
```

**Usage**:

```yaml
# Example: Create LoadBalancer service
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: my-app
```

**Verification**:

```bash
# View MetalLB pods
kubectl get pods -n metallb-system

# Check IP address pools
kubectl get ipaddresspool -n metallb-system

# View allocated IPs
kubectl get svc -A | grep LoadBalancer

# Get specific service IP
kubectl get svc <service-name> -n <namespace>
```

**Common Tasks**:

```bash
# Add additional IP pool
kubectl apply -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: secondary-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.10.209.200-10.10.209.250
  autoAssign: false  # Manual assignment only
EOF

# Request specific IP for service
# Add annotation to service:
# metallb.universe.tf/address-pool: secondary-pool
```

---

### OpenEBS

**Disclaimer**: I use this as my hostpath storage interface - this is fine for dev, testing, homelabs, etc. but I plan to setup Ceph or NAS options at some point, time and budget allowing.

**Purpose**: Cloud-native storage solution for Kubernetes persistent volumes

**Namespace**: `openebs`

**Features**:
- Dynamic volume provisioning
- Local PV storage
- Replicated storage options
- Storage classes for different workload types

**Storage Classes**:

The `manifests/openebs-lite-sc.yaml` defines storage classes for different use cases:

```yaml
# Example storage classes
- openebs-hostpath    # Simple hostpath volumes
- openebs-device      # Block device volumes
```

**Usage**:

```yaml
# Example: Request persistent volume
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: openebs-hostpath
  resources:
    requests:
      storage: 10Gi
```

**Verification**:

```bash
# View OpenEBS pods
kubectl get pods -n openebs

# List storage classes
kubectl get sc

# View persistent volumes
kubectl get pv

# Check PVC status
kubectl get pvc -A

# View OpenEBS volumes
kubectl get bd -n openebs  # Block devices
```

**Common Tasks**:

```bash
# Check storage capacity
kubectl get pv -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,STATUS:.status.phase

# View volume details
kubectl describe pv <pv-name>

# Verify volume binding
kubectl describe pvc <pvc-name> -n <namespace>
```

## Management

### Viewing Application Status

```bash
# List all infrastructure applications
kubectl get applications -n argocd

# Get detailed application status
argocd app get cert-manager
argocd app get metallb
argocd app get openebs

# View sync status
argocd app list | grep infrastructure
```

### Updating Components

All updates are made via Git commits:

```bash
# 1. Update manifest files
git checkout -b update-cert-manager
# Edit infrastructure/cert-manager/app.yaml or manifests
git commit -m "Update cert-manager to v1.14.0"
git push

# 2. ArgoCD automatically syncs changes
# Or manually trigger sync:
argocd app sync cert-manager

# 3. Verify update
kubectl get pods -n cert-manager
```

### Adding New Components

1. Create component directory structure:
```bash
mkdir infrastructure/my-component
```

2. Create ArgoCD application manifest:
```yaml
# infrastructure/my-component/app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-component
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-repo
    targetRevision: HEAD
    path: infrastructure/my-component/manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: my-component
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

3. Commit and push changes - ArgoCD will deploy automatically.

`root-app.yaml` will pick up any new applications in the `infrastructure` directory and deploy them.

### Removing Components

```bash
# Delete application from ArgoCD
kubectl delete application <app-name> -n argocd

# Or use ArgoCD CLI
argocd app delete <app-name>

# Remove from root-app.yaml to prevent recreation
```

## Troubleshooting

### Application Not Syncing

```bash
# Check application status
argocd app get <app-name>

# View sync errors
kubectl describe application <app-name> -n argocd

# Force sync
argocd app sync <app-name> --force

# Refresh application
argocd app sync <app-name> --prune
```

### cert-manager Issues

```bash
# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Verify webhook
kubectl get validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations

# Check certificate status
kubectl describe certificate <cert-name> -n <namespace>

# View certificate request details
kubectl get certificaterequest -A
```

### MetalLB Issues

```bash
# Check MetalLB speaker logs (one per node)
kubectl logs -n metallb-system -l component=speaker

# Check controller logs
kubectl logs -n metallb-system -l component=controller

# Verify IP pool configuration
kubectl get ipaddresspool -n metallb-system -o yaml

# Check L2 advertisements
kubectl get l2advertisement -n metallb-system

# Service not getting IP
kubectl describe svc <service-name> -n <namespace>
```

### OpenEBS Issues

```bash
# Check OpenEBS control plane
kubectl logs -n openebs -l app=openebs

# View storage pool status
kubectl get sp -n openebs

# Check volume replica status
kubectl get cvr -n openebs

# PVC stuck in Pending
kubectl describe pvc <pvc-name> -n <namespace>
kubectl get events -n <namespace> --field-selector involvedObject.name=<pvc-name>

# Check node storage capacity
kubectl get nodes -o custom-columns=NAME:.metadata.name,STORAGE:.status.capacity.ephemeral-storage
```

## Backup and Recovery

### Backup Infrastructure Configuration

All infrastructure is defined in Git, providing automatic version control and backup. Additional considerations:

```bash
# Export ArgoCD application definitions
kubectl get applications -n argocd -o yaml > argocd-apps-backup.yaml

# Backup cert-manager certificates
kubectl get certificates -A -o yaml > certificates-backup.yaml
kubectl get secrets -A -l cert-manager.io/certificate-name -o yaml > cert-secrets-backup.yaml

# Backup MetalLB configuration
kubectl get ipaddresspool,l2advertisement -n metallb-system -o yaml > metallb-config-backup.yaml

# Backup OpenEBS storage classes
kubectl get sc -o yaml > storage-classes-backup.yaml
```

### Restore Process

```bash
# Restore via ArgoCD (preferred)
kubectl apply -f infrastructure/root-app.yaml
argocd app sync --all

# Manual restore if needed
kubectl apply -f argocd-apps-backup.yaml
```

# Upcoming additions 

## Monitoring

### Recommended Metrics

Deploy Prometheus to monitor infrastructure components:

```bash
# cert-manager metrics
kubectl port-forward -n cert-manager svc/cert-manager 9402:9402
curl localhost:9402/metrics

# MetalLB metrics
kubectl port-forward -n metallb-system <speaker-pod> 7472:7472
curl localhost:7472/metrics

# OpenEBS metrics
kubectl port-forward -n openebs <maya-apiserver-pod> 9500:9500
curl localhost:9500/metrics
```

### Key Metrics to Track

- **cert-manager**: Certificate expiry, renewal success rate
- **MetalLB**: IP allocation, ARP responses, BGP session status
- **OpenEBS**: Volume provisioning time, IOPS, capacity utilization

## Security Considerations

### Network Policies

Consider implementing network policies to restrict traffic:

```yaml
# Example: Restrict cert-manager to only DNS providers
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: cert-manager-egress
  namespace: cert-manager
spec:
  podSelector:
    matchLabels:
      app: cert-manager
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
```

### RBAC

Review and restrict service account permissions:

```bash
# View service account permissions
kubectl get clusterrolebindings -o yaml | grep -A 5 "name: cert-manager"
kubectl get clusterrolebindings -o yaml | grep -A 5 "name: metallb"
kubectl get clusterrolebindings -o yaml | grep -A 5 "name: openebs"
```

## Performance Tuning

### cert-manager

```yaml
# Increase concurrent workers for high certificate volume
# In cert-manager deployment:
args:
- --max-concurrent-challenges=100
```

### MetalLB

```yaml
# For high-traffic environments, adjust speaker resources
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
```

### OpenEBS

```yaml
# Configure appropriate storage classes for workload types
# For databases: openebs-lvmpv (better performance)
# For logs: openebs-hostpath (simple, fast)
# For replicated data: openebs-jiva (redundancy)
```

## Related Documentation

- [Root README](../README.md) - Repository overview
- [Cluster Bootstrap README](../cluster-bootstrap/README.md) - Cluster deployment
- [cert-manager Docs](https://cert-manager.io/docs/)
- [MetalLB Docs](https://metallb.universe.tf/)
- [OpenEBS Docs](https://openebs.io/docs/)
- [ArgoCD Docs](https://argo-cd.readthedocs.io/)