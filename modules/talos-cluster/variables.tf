variable "name" {
  type        = string
  description = "prefixes resource names"
}
variable "endpoint" {
  type        = string
  description = "cluster endpoint"

  validation {
    condition     = startswith(var.endpoint, "http") == false && endswith(var.endpoint, "6443") == false
    error_message = "must not contain protocol or port"
  }
}

# TODO: add cluster autoscaling
variable "features" {
  type = object({
    ip6 = optional(bool, false)
    ip4 = optional(bool, false)
  })
  description = "enables public ipv4 / ipv6 on servers"
  default     = {}

  validation {
    condition     = var.features.ip6 || var.features.ip4
    error_message = "ip6 and / or ip4 must be true"
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
