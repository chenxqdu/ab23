data "aws_ecr_authorization_token" "token" {
  
}

resource "kubernetes_secret" "docker" {
  metadata {
    name      = "docker-cfg"
    namespace = kubernetes_namespace.piggymetrics.metadata.0.name
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${data.aws_ecr_authorization_token.token.proxy_endpoint}" = {
          auth = "${data.aws_ecr_authorization_token.token.authorization_token}"
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}