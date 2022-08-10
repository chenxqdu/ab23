variable "aws_region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.21"
}

variable "node_group_max" {
  type = number
}

variable "node_group_min" {
  type = number
}

variable "node_group_desire" {
  type = number
}

variable "instance_type" {
  type = list(string)
}