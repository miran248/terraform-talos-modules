variable "prefix" {
  type        = string
  description = "scaleway resource name prefix, must be unique"
}
variable "zone" {
  type        = string
  description = "scaleway zone"
}

variable "mode" {
  type        = string
  description = "IP family for pool nodes"
  default     = "ipv6"
  validation {
    condition     = contains(["ipv6", "ipv4"], var.mode)
    error_message = "mode must be ipv6 or ipv4"
  }
}

variable "control_planes" {
  type = list(object({
    type    = string
    image   = string
    aliases = optional(list(string), [])
    patches = optional(list(string), [])
    removed = optional(bool, false)
  }))
  description = "define control planes"
  default     = []
}
variable "workers" {
  type = list(object({
    type    = string
    image   = string
    aliases = optional(list(string), [])
    patches = optional(list(string), [])
    removed = optional(bool, false)
  }))
  description = "define workers"
  default     = []
}

variable "patches" {
  type = object({
    common         = optional(list(string), [])
    control_planes = optional(list(string), [])
    workers        = optional(list(string), [])
  })
  description = "pool-wide config patches"
  default     = {}
}
