terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

# Gateway API CRDs
data "http" "gateway_api_crds" {
  for_each = toset([
    "gateway.networking.k8s.io_gatewayclasses.yaml",
    "gateway.networking.k8s.io_gateways.yaml",
    "gateway.networking.k8s.io_httproutes.yaml",
    "gateway.networking.k8s.io_referencegrants.yaml",
    "gateway.networking.k8s.io_grpcroutes.yaml"
  ])
  url = "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/standard/${each.value}"
}

resource "kubernetes_manifest" "gateway_api_crds" {
  for_each = data.http.gateway_api_crds
  manifest = {
    for k, v in yamldecode(each.value.response_body) : k => v
    if k != "status"
  }
}

# Cilium Helm Release
resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = "1.18.0"
  namespace  = "kube-system"
  timeout    = 1200

  depends_on = [
    kubernetes_manifest.gateway_api_crds
  ]

  set {
    name  = "ipam.mode"
    value = "kubernetes"
  }

  set {
    name  = "kubeProxyReplacement"
    value = "true"
  }

  set {
    name  = "securityContext.capabilities.ciliumAgent"
    value = "{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
  }

  set {
    name  = "securityContext.capabilities.cleanCiliumState"
    value = "{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
  }

  set {
    name  = "cgroup.autoMount.enabled"
    value = "false"
  }

  set {
    name  = "cgroup.hostRoot"
    value = "/sys/fs/cgroup"
  }

  set {
    name  = "k8sServiceHost"
    value = "localhost"
  }

  set {
    name  = "k8sServicePort"
    value = "7445"
  }

  set {
    name  = "gatewayAPI.enabled"
    value = "true"
  }

  set {
    name  = "gatewayAPI.enableAlpn"
    value = "true"
  }

  set {
    name  = "gatewayAPI.enableAppProtocol"
    value = "true"
  }
}
