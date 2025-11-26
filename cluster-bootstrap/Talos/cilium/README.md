# Cilium & Gateway API Module

This Terraform module installs the Cilium CNI and Gateway API CRDs onto the Talos cluster.

## Responsibilities

1.  **Gateway API**: Installs the standard Gateway API CRDs (v1.2.0).
2.  **Cilium CNI**: Deploys Cilium via Helm (v1.18.0) with specific configuration for Talos.

## Prerequisites

-   The Talos cluster must be successfully provisioned (Phase 1).
-   A valid `kubeconfig` file must be available. By default, it looks for `../terraform/kubeconfig`.

## Usage

```bash
terraform init
terraform apply
```

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `kubeconfig_path` | Path to the kubeconfig file generated in Phase 1 | `../terraform/kubeconfig` |

## Cilium Configuration Details

The Cilium Helm release is configured with the following key settings:

-   **`ipam.mode=kubernetes`**: Delegates IPAM to Kubernetes.
-   **`kubeProxyReplacement=true`**: Replaces kube-proxy for better performance.
-   **`securityContext.capabilities`**: Grants necessary privileges for Cilium to run on Talos.
-   **`cgroup.hostRoot=/sys/fs/cgroup`**: Adapts to Talos's cgroup mount point.
-   **`k8sServiceHost=localhost`**: Points to the local API server (Talos standard).
-   **`gatewayAPI.enabled=true`**: Enables Gateway API support.

## Troubleshooting

### Timeout Errors

If you see `context deadline exceeded` during `helm_release.cilium`, it usually means the Cilium agent is taking too long to start or pull images. The timeout has been set to 20 minutes to mitigate this, but slow internet connections may still cause issues.

### CRD Errors

If you see errors related to missing CRDs, ensure that the `kubernetes_manifest.gateway_api_crds` resource has applied successfully. The module uses `depends_on` to enforce this order.
