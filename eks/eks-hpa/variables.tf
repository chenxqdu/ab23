variable "aws_region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "microservices" {
  type = map(object({
    type = string,
    replicas_number = number
  }))
}

