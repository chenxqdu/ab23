# data "aws_iam_role" "eks-node" {
#   name = "${var.cluster_name}-node"
# }

resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile-${var.cluster_name}"
  role = "${var.cluster_name}-node"
}
