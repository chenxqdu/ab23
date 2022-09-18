data "aws_eks_cluster" "default" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "default" {
  name = var.cluster_name
}

# OIDC Provider
data "tls_certificate" "default" {
  url = data.aws_eks_cluster.default.identity.0.oidc.0.issuer
}

data "terraform_remote_state" "cluster" {
  backend = "local"

  config = {
    path = "../eks-cluster/terraform.tfstate"
  }
}

data "aws_iam_policy_document" "k8s-acc-AdotCollectorRoleTrustPolicy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.default.identity.0.oidc.0.issuer, "https://", "")}:aud" 
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.default.identity.0.oidc.0.issuer, "https://", "")}:sub" 
      values   = ["system:serviceaccount:observability:adot-collector"]
    }

    principals {
      identifiers = [data.terraform_remote_state.cluster.outputs.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "k8s-acc-AdotCollectorRole" {
  assume_role_policy = data.aws_iam_policy_document.k8s-acc-AdotCollectorRoleTrustPolicy.json
  name               = "${var.cluster_name}-AdotCollectorRole"
}

resource "aws_iam_role_policy_attachment" "adot-AmazonPrometheusRemoteWriteAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
  role       = aws_iam_role.k8s-acc-AdotCollectorRole.id
}

## to check if needed for adot addon 0.58.0 and above     
# resource "aws_iam_role_policy_attachment" "adot-AmazonPrometheusQueryAccess" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
#   role       = aws_iam_role.k8s-acc-AdotCollectorRole.id
# }

resource "aws_iam_role_policy_attachment" "adot-AWSXrayWriteOnlyAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
  role       = aws_iam_role.k8s-acc-AdotCollectorRole.id
}

resource "aws_iam_role_policy_attachment" "adot-CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.k8s-acc-AdotCollectorRole.id
}

