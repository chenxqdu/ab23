resource "kubernetes_horizontal_pod_autoscaler" "piggymetrics" {

  depends_on = [helm_release.metrics-server]

  for_each = var.microservices

  metadata {
    name = "${each.key}-hpa"
    namespace = "piggymetrics"
  }

  spec {
    min_replicas = each.value.replicas_number
    max_replicas = 10
    target_cpu_utilization_percentage = 80
    
    scale_target_ref {
      api_version = "apps/v1"
      kind = each.value.type == "stateful_set" ? "StatefulSet" : "Deployment"
      name = each.key
    }
  }
}
