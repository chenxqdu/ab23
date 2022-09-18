data "aws_region" "current" {
  name = var.aws_region
}
data "aws_caller_identity" "current" {

}

## private ecr
# resource "aws_ecr_repository" "default" {
#   name                 = "${var.cluster_name}-ecr"
# }

## public ecr
resource "aws_ecrpublic_repository" "default" {
  provider = aws.us-east-1
  repository_name     = "${var.cluster_name}-ecr-pb"
}

data "local_file" "buildspec" {
  filename = "${path.module}/buildspec.yml.tmpl"
}

resource "aws_codebuild_project" "default" {
  provider = aws.default
  
  badge_enabled  = false
  build_timeout  = 60
  name           = "${var.cluster_name}-codebuild"
  queued_timeout = 480
  depends_on     = [aws_iam_role.default]
  service_role   = aws_iam_role.default.arn
  source_version = "main"
  tags           = {}

  artifacts {
    encryption_disabled    = false
    override_artifact_name = false
    type                   = "NO_ARTIFACTS"
  }

  cache {
    modes = []
    type  = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    type                        = "LINUX_CONTAINER"
    environment_variable {
      name  = "REPO_ECR"
      value = aws_ecrpublic_repository.default.repository_uri
    }
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }

    s3_logs {
      encryption_disabled = false
      status              = "DISABLED"
    }
  }

  source {
    type            = "GITHUB"
    location        = var.git_url
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }

    buildspec = data.local_file.buildspec.content
  }

}

resource "aws_codebuild_webhook" "default" {
  project_name = aws_codebuild_project.default.name
  build_type   = "BUILD"
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "main"
    }

    filter {
      type    = "FILE_PATH"
      pattern = "/piggymetrics/config/*"
    }

  }
}