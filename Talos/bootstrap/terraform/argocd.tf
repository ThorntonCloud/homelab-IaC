resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "9.0.3"

  values = [
    file("${path.module}/argocd-values.yaml")
  ]

  timeout       = 900
  wait          = false
  wait_for_jobs = false
}

# Apply root app to bootstrap GitOps
resource "null_resource" "argocd_bootstrap" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=/tmp/kubeconfig
      
      kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
      kubectl apply -f ../../../Apps/infrastructure/root-app.yaml
      echo "GitOps bootstrap complete! Argo CD is now managing the cluster."
    EOT
  }
}