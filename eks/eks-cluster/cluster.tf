provider "aws" {
  region = var.aws_region
}

resource "aws_eks_cluster" "k8s-acc" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.k8s-acc-cluster.arn

  vpc_config {
    subnet_ids = aws_subnet.k8s-acc.*.id
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.k8s-acc-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.k8s-acc-AmazonEKSVPCResourceController,
  ]
}

resource "aws_eks_node_group" "k8s-acc" {
  cluster_name    = aws_eks_cluster.k8s-acc.name
  node_group_name = var.cluster_name
  node_role_arn   = aws_iam_role.k8s-acc-node.arn
  subnet_ids      = aws_subnet.k8s-acc.*.id
  instance_types  = var.instance_type

  scaling_config {
    desired_size = var.node_group_desire
    max_size     = var.node_group_max
    min_size     = var.node_group_min
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.k8s-acc-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.k8s-acc-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.k8s-acc-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "local_file" "kubeconfig" {
  depends_on = [
    aws_eks_cluster.k8s-acc,
    aws_eks_node_group.k8s-acc,
  ]

  sensitive_content = templatefile("${path.module}/kubeconfig.tpl", {
    cluster_name = var.cluster_name,
    clusterca    = aws_eks_cluster.k8s-acc.certificate_authority[0].data,
    endpoint     = aws_eks_cluster.k8s-acc.endpoint,
    })
  filename          = "./kubeconfig-${var.cluster_name}"
}