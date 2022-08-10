variable "aws_region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "microservices" {
  type = map(object({
    type = string,
    image_url = string,
    port = number,
    target_port = number,
    replicas_number = number,
    service_type = string
  }))
}

