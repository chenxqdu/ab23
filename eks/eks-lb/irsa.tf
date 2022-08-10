## OIDC Provider
data "tls_certificate" "default" {
  url = data.aws_eks_cluster.default.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "default" {
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.default.certificates.0.sha1_fingerprint]
  url = data.aws_eks_cluster.default.identity.0.oidc.0.issuer
}

data "aws_iam_policy_document" "k8s-acc-AWSLoadBalancerRoleTrustPolicy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.default.url, "https://", "")}:aud" 
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.default.url, "https://", "")}:sub" # todo
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.default.arn] # todo
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

