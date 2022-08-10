
resource "aws_iam_role" "default" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "codebuild.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  force_detach_policies = false
  max_session_duration  = 3600
  name                  = "${var.cluster_name}-codebuild"
}

resource "aws_iam_policy" "CodeBuildBasePolicy" {
  description = "Policy used in trust relationship with CodeBuild v0.4"
  name        = "${var.cluster_name}-CodeBuildBasePolicy"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ]
          Effect = "Allow"
          Resource = [
             format("arn:aws:logs:%s:%s:log-group:/aws/codebuild/%s",data.aws_region.current.name,data.aws_caller_identity.current.account_id,aws_codebuild_project.default.name),
             format("arn:aws:logs:%s:%s:log-group:/aws/codebuild/%s:*", data.aws_region.current.name,data.aws_caller_identity.current.account_id,aws_codebuild_project.default.name)
          ]
        },
        {
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketAcl",
            "s3:GetBucketLocation",
          ]
          Effect = "Allow"
          Resource = [
            format("arn:aws:s3:::codepipeline-%s-*",data.aws_region.current.name)
          ]
        },
        {
          Action = [
            "codebuild:CreateReportGroup",
            "codebuild:CreateReport",
            "codebuild:UpdateReport",
            "codebuild:BatchPutTestCases",
            "codebuild:BatchPutCodeCoverages",
          ]
          Effect = "Allow"
          Resource = [
            format("arn:aws:codebuild:%s:%s:report-group/%s-*",data.aws_region.current.name,data.aws_caller_identity.current.account_id,aws_codebuild_project.default.name),
          ]
        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_role_policy_attachment" "codebuild_BasePolicy" {
  policy_arn = aws_iam_policy.CodeBuildBasePolicy.arn
  role       = aws_iam_role.default.id
}

resource "aws_iam_role_policy_attachment" "codebuild_ECRPublicFull" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicFullAccess"
  role       = aws_iam_role.default.id
}

# resource "aws_iam_role_policy_attachment" "codebuild_ECRFull" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
#   role       = aws_iam_role.default.id
# }

 