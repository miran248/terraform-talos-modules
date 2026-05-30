variable "name" {
  type        = string
  description = "cluster name"
}
variable "endpoint" {
  type        = string
  description = "cluster DNS endpoint (e.g. prod.example.com)"
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
    nodes = map(object({
      kind    = string
      name    = string
      aliases = list(string)
      ip_64   = string
      patches = list(string)
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
