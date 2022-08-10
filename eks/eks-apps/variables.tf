variable "aws_region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "env_vars" {
  type = map
  default = {
    CONFIG_SERVICE_PASSWORD = "password",
    NOTIFICATION_SERVICE_PASSWORD = "password",
    STATISTICS_SERVICE_PASSWORD = "password",
    ACCOUNT_SERVICE_PASSWORD = "password",
    MONGODB_PASSWORD = "password",
    INIT_DUMP="account-service-dump.js"
  }
}

variable "microservices" {
  type = map(object({
    type = string
    image_url = string,
    port = number,
    target_port = number,
    replicas_number = number,
    service_type = string,
    cpu_limit = string
  }))
}

variable "registry_server" {
  type = string
  default = "registry"
}
