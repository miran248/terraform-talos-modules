variable "prefix" {
  type        = string
  description = "prefixes resource names"
}

variable "zone" {
  type = object({
    ips4 = object({
      load_balancer  = string
      router         = string
      router_client  = string
      control_planes = list(string)
      workers        = list(string)
    })
    cloud  = number
    region = number
    zone   = number
  })
  description = "network zone module outputs"
}

variable "nodes" {
  type = object({
    control_planes = optional(list(object({
      server_type = string
      patches     = optional(list(string), [])
      node_labels = optional(map(any), {})
      removed     = optional(bool, false)
    })), [])
    workers = optional(list(object({
      server_type = string
      patches     = optional(list(string), [])
      node_labels = optional(map(any), {})
      removed     = optional(bool, false)
    })), [])
  })
  description = "control planes and workers with machine specific configs"
}

variable "patches" {
  type = object({
    control_planes = optional(list(string), [])
    workers        = optional(list(string), [])
  })
  description = "common config patches"
  default     = {}
}

variable "node_labels" {
  type = object({
    control_planes = optional(map(any), { role = "control-plane" })
    workers        = optional(map(any), { role = "worker" })
  })
  description = "common node labels"
  default     = {}
}
