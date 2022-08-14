resource "aws_eks_addon" "adot" {
  depends_on = [
    helm_release.cert-manager,
    kubernetes_manifest.clusterrolebinding_eks_addon_manager_otel,
    kubernetes_manifest.rolebinding_opentelemetry_operator_system_eks_addon_manager,
  ]

  cluster_name = var.cluster_name
  addon_name   = "adot"
}
