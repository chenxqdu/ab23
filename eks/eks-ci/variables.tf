variable "aws_region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "ecr_repo" {
  type = string
  default = "config"
}

variable "git_url" {
  type = string
  default = "config"
}