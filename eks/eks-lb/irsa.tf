## OIDC Provider
data "tls_certificate" "default" {
  url = data.aws_eks_cluster.default.identity.0.oidc.0.issuer
}

data "terraform_remote_state" "cluster" {
  backend = "local"

  config = {
    path = "../eks-cluster/terraform.tfstate"
  }
}

data "aws_iam_policy_document" "k8s-acc-AWSLoadBalancerRoleTrustPolicy" {
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
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [data.terraform_remote_state.cluster.outputs.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_policy" "k8s-acc-AWSLoadBalancerControllerIAMPolicy" {
  name        = "${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "AWS LoadBalancer Controller IAM Policy"
  policy = file("iam-policy.json")
}

resource "aws_iam_role" "k8s-acc-AWSEKSLoadBalancerControllerRole" {
  assume_role_policy = data.aws_iam_policy_document.k8s-acc-AWSLoadBalancerRoleTrustPolicy.json
  name               = "${var.cluster_name}-AWSEKSLoadBalancerControllerRole"
}

resource "aws_iam_role_policy_attachment" "k8s-acc-AWSLoadBalancerControllerIAMPolicy" {
  policy_arn = aws_iam_policy.k8s-acc-AWSLoadBalancerControllerIAMPolicy.arn
  role       = aws_iam_role.k8s-acc-AWSEKSLoadBalancerControllerRole.name
}

