resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "9.0.3"

  values = [
    file("${path.module}/argocd-values.yaml")
  ]

  depends_on = [
    talos_cluster_kubeconfig.kubeconfig,
    data.talos_cluster_health.health
  ]
}

resource "local_sensitive_file" "kubeconfig" {
  content         = talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  filename        = "${path.module}/kubeconfig"
  file_permission = "0600"
}

resource "null_resource" "argocd_bootstrap" {
  depends_on = [
    helm_release.argocd,
    local_sensitive_file.kubeconfig
  ]

  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG=${path.module}/kubeconfig
      
      echo "Waiting for Argo CD to be ready..."
      kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
      
      echo "Applying root application..."
      kubectl apply -f ${path.module}/../../ArgoCD/bootstrap/root-app.yaml
      
      echo "Argo CD bootstrap complete!"
    EOT
  }

  triggers = {
    root_app_content = filesha256("${path.module}/../../ArgoCD/bootstrap/root-app.yaml")
  }
}

provider "helm" {
  kubernetes {
    host                   = yamldecode(talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw).clusters[0].cluster.server
    client_certificate     = base64decode(yamldecode(talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw).users[0].user["client-certificate-data"])
    client_key             = base64decode(yamldecode(talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw).users[0].user["client-key-data"])
    cluster_ca_certificate = base64decode(yamldecode(talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw).clusters[0].cluster["certificate-authority-data"])
  }
}