variable "name" {
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
variable "talos_version" {
  type        = string
  description = "talos version"
}
variable "kubernetes_version" {
  type        = string
  description = "kubernetes version"
}

variable "pools" {
  type = list(object({
    prefix = string
    control_planes = map(object({
      name                  = string
      aliases               = list(string)
      public_ip6_network_64 = string
      public_ip6_64         = string
      public_ip6            = string
      patches               = list(string)
    }))
    workers = map(object({
      name                  = string
      aliases               = list(string)
      public_ip6_network_64 = string
      public_ip6_64         = string
      public_ip6            = string
      patches               = list(string)
    }))
  }))
  description = "list of node pool module outputs"
  validation {
    condition     = length([for i, pool in var.pools : pool.prefix]) == length(distinct([for i, pool in var.pools : pool.prefix]))
    error_message = "pool prefixes must be unique"
  }
}

variable "patches" {
  type = object({
    common         = optional(list(string), [])
    control_planes = optional(list(string), [])
    workers        = optional(list(string), [])
  })
  description = "cluster-wide config patches"
  default     = {}
}
