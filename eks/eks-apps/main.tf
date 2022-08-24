resource "kubernetes_namespace" "piggymetrics" {
  metadata {
    name = "piggymetrics"
  }
}

resource "kubernetes_stateful_set" "piggymetrics" {
  # depends_on = [
  #     kubernetes_secret.docker,
  # ]

  for_each = { for k,v in var.microservices : k => v if v.type == "stateful_set" }

  metadata {
    name = each.key
    namespace = kubernetes_namespace.piggymetrics.metadata.0.name
  }

  spec {
    service_name = each.key
    replicas = each.value.replicas_number

    selector {
      match_labels = {
        k8s-app = each.key
      }
    }

    template {
      metadata {
        labels = {
          k8s-app = each.key
        } 
      }
      spec {
        # image_pull_secrets {
        #   name = "docker-cfg"
        # }

        container{
          image = each.value.image_url
          name = each.key
          image_pull_policy = "Always"
          port {
            container_port = each.value.port 
          }
          env {
            name = "eureka_defaultzone"
            value = var.registry_server
          }
          dynamic "env" {
            for_each = var.env_vars
            content {
              name = env.key
              value = env.value
            }
          }
          resources {
            limits = {
              cpu = each.value.cpu_limit
            }
          }
        }  
      }
    }
  }
}

resource "kubernetes_deployment" "piggymetrics" {

  for_each = { for k,v in var.microservices : k => v if v.type == "deployment" }

  metadata {
    name = each.key
    namespace = kubernetes_namespace.piggymetrics.metadata.0.name
  }

  spec {
    replicas = each.value.replicas_number

    selector {
      match_labels = {
        k8s-app = each.key
      }
    }

    template {
      metadata {
        labels = {
          k8s-app = each.key
        } 
      }
      spec {
        container{
          image = each.value.image_url
          name = each.key
          image_pull_policy = "Always"
          port {
            container_port = each.value.port 
          }
          env {
            name = "eureka_defaultzone"
            value = var.registry_server
          }
          env {
            name = "OTEL_RESOURCE_ATTRIBUTES"
            value = "service.name=${each.key}"
          }
          env {
            name = "OTEL_EXPORTER_OTLP_ENDPOINT"
            value = "http://my-collector-collector.observability:4317"
          }
          dynamic "env" {
            for_each = var.env_vars
            content {
              name = env.key
              value = env.value
            }
          }
          resources {
            limits = {
              cpu = each.value.cpu_limit
            }
          }
        } 
      }
    }
  }
}

resource "kubernetes_service" "piggymetrics" {
  for_each = var.microservices

  metadata {
    name = each.key
    namespace = kubernetes_namespace.piggymetrics.metadata.0.name 
    annotations =  each.value.service_type == "LoadBalancer" ? {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "external",
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip",
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing" } : {}
  }

  spec {
    selector = {
      k8s-app = each.key
    }
    port {
      port = each.value.port
      target_port = each.value.target_port
    }
    type = each.value.service_type
    cluster_ip = each.value.type == "stateful_set" ? "None" : null
  }
}
