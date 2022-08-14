## OIDC Provider

data "tls_certificate" "k8s-acc" {
  url = aws_eks_cluster.k8s-acc.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "k8s-acc" {
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.k8s-acc.certificates.0.sha1_fingerprint]
  url = aws_eks_cluster.k8s-acc.identity.0.oidc.0.issuer
}

output oidc_provider_arn {
  value = aws_iam_openid_connect_provider.k8s-acc.arn
}

terraform {
  backend "local" {
    path = "../eks-cluster/terraform.tfstate"
  }
}