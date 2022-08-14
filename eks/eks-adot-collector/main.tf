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

resource "kubernetes_manifest" "adot-collector-xray" {
  depends_on = [
    kubernetes_service_account.adot-collector,
  ]

  manifest = {
    apiVersion = "opentelemetry.io/v1alpha1"
    kind = "OpenTelemetryCollector"
    metadata = {
      name = "my-collector-xray"
      namespace = "observability"
    }
    spec = {
      config = <<-EOT
      receivers:
        otlp:
          protocols:
            grpc:
              endpoint: 0.0.0.0:4317
            http:
              endpoint: 0.0.0.0:4318
      processors:
      
      exporters:
        awsxray:
          region: ${var.aws_region}
      
      service:
        pipelines:
          traces:
            receivers: [otlp]
            processors: []
            exporters: [awsxray]
      
      EOT
      mode = "deployment"
      serviceAccount = "adot-collector"
    }
  }
}