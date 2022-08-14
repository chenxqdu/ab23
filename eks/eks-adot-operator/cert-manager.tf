resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert-manager" {
  name             = "cert-manager"
  namespace        = kubernetes_namespace.cert-manager.metadata[0].name
  create_namespace = false
  chart            = "cert-manager"
  repository       = "https://charts.jetstack.io"
  version          = "v1.8.2"

  set {
    name  = "startupapicheck.enabled"
    value = "false"
  }
  
  set {
    name = "installCRDs"
    value = "true"
  }
}