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
