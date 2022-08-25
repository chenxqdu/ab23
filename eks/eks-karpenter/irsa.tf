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

data "aws_iam_policy_document" "karpenter_controller" {
  statement {
    actions = [
      "ec2:CreateLaunchTemplate",
      "ec2:CreateFleet",
      "ec2:CreateTags",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSpotPriceHistory",
      "pricing:GetProducts",
      "ec2:TerminateInstances",
      "ec2:DeleteLaunchTemplate",
      "ec2:RunInstances",
      "ssm:GetParameter",
      "iam:PassRole"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "k8s-acc-KarpenterControllerPolicy" {
  name = "${var.cluster_name}-KarpenterControllerPolicy"
  policy      = data.aws_iam_policy_document.karpenter_controller.json
  
}

data "aws_iam_policy_document" "k8s-acc-KarpenterControllerRoleTrustPolicy" {
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
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }

    principals {
      identifiers = [data.terraform_remote_state.cluster.outputs.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "k8s-acc-KarpenterControllerRole" {
  assume_role_policy = data.aws_iam_policy_document.k8s-acc-KarpenterControllerRoleTrustPolicy.json
  name               = "${var.cluster_name}-KarpenterCollectorRole"
}

resource "aws_iam_role_policy_attachment" "adot-AmazonPrometheusRemoteWriteAccess" {
  policy_arn = aws_iam_policy.k8s-acc-KarpenterControllerPolicy.arn
  role       = aws_iam_role.k8s-acc-KarpenterControllerRole.id
}

