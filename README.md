1. Deploy cluster manually:
```bash
terraform init
terraform apply
```

2. Install GitHub Actions Runner Controller:
```bash
NAMESPACE="arc-systems"
helm install arc \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
```

3. Install GitHub Actions Runner Scale Set:
```bash
INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/<your_enterprise/org/repo>"
GITHUB_PAT="<PAT>"
helm install "${INSTALLATION_NAME}" \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    --set githubConfigUrl="${GITHUB_CONFIG_URL}" \
    --set githubConfigSecret.github_token="${GITHUB_PAT}" \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```

4. Verify with:
```bash
kubectl get pods -n arc-systems

# You should see something like this:
NAME                                     READY   STATUS    RESTARTS   AGE
arc-gha-rs-controller-55558fffc7-bqjgg   1/1     Running   0          4h2m
arc-runner-set-754b578d-listener         1/1     Running   0          4h1m
```