variable "debug" {
  type        = bool
  description = "controls talos debug flag"
  default     = false
}

variable "cluster_name" {
  type        = string
  description = "cluster name"
}
variable "endpoint" {
  type        = string
  description = "cluster endpoint"

  validation {
    condition     = startswith(var.endpoint, "http") == false && endswith(var.endpoint, "6443") == false
    error_message = "must not contain protocol or port"
  }
}

variable "layout" {
  type = object({
    masks4 = object({ machines = string })
    cidrs4 = object({ machines = string, services = string, pods = string })
  })
  description = "network layout module outputs"
}

variable "pools" {
  type = list(object({
    control_planes = map(object({
      name        = string
      server_type = string
      patches     = list(string)
      node_labels = map(any)
    }))
    workers = map(object({
      name        = string
      server_type = string
      patches     = list(string)
      node_labels = map(any)
    }))
  }))
  description = "list of node pool module outputs"
}

variable "talos_version" {
  type        = string
  description = "talos version"
}
variable "kubernetes_version" {
  type        = string
  description = "kubernetes version"
}
