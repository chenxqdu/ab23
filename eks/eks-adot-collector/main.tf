provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token
}

resource "kubernetes_namespace" "observability" {
  metadata {
    name = "observability"
  }
}

resource "kubernetes_service_account" "adot-collector" {
  depends_on = [
    kubernetes_namespace.observability,
  ]

  metadata {
    name = "adot-collector"
    namespace = "observability"
    labels = {
      "app.kubernetes.io/instance" = "adot-collector"
      "app.kubernetes.io/name" = "adot-collector"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.k8s-acc-AdotCollectorRole.arn
    }
  }  
}

resource "kubernetes_cluster_role" "otel-prometheus-role" {
  metadata {
    name = "otel-prometheus-role"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "pods","services","endpoints","nodes/proxy"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    non_resource_urls = ["/metrics"]
    verbs      = ["get"]
  }

}

resource "kubernetes_cluster_role_binding" "otel-prometheus-role-binding" {
  metadata {
    name = "otel-prometheus-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "otel-prometheus-role"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "adot-collector"
    namespace = "observability"
  }
}

resource "kubernetes_manifest" "adot-collector" {
  depends_on = [
    kubernetes_service_account.adot-collector,
  ]

  manifest = {
    apiVersion = "opentelemetry.io/v1alpha1"
    kind = "OpenTelemetryCollector"
    metadata = {
      name = "my-collector"
      namespace = "observability"
    }
    spec = {
      config = "${file("collector-config.yaml")}"
      mode = "deployment"
      serviceAccount = "adot-collector"
    }
  }
}