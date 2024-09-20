variable "cluster" {
  type = object({
    name = string
    patches = object({
      control_planes = list(string)
      workers        = list(string)
    })
  })
  description = "cluster config module outputs"
}

variable "zone" {
  type        = number
  description = "defines third octet, 192.168.zzz._"

  validation {
    condition     = var.zone >= 1 && var.zone <= 255
    error_message = "must be between 1 and 255, inclusive"
  }
}

variable "patches" {
  type = object({
    common         = optional(list(string), [])
    control_planes = optional(list(string), [])
    workers        = optional(list(string), [])
  })
  description = "node pool config patches"
  default     = {}
}

variable "nodes" {
  type = object({
    control_planes = optional(list(object({
      server_type = string
      patches     = optional(list(string), [])
      removed     = optional(bool, false)
    })), [])
    workers = optional(list(object({
      server_type = string
      patches     = optional(list(string), [])
      removed     = optional(bool, false)
    })), [])
  })
  description = "control planes and workers with node specific configs"

  validation {
    condition     = length(var.nodes.control_planes) <= 9 && length(var.nodes.workers) <= 229
    error_message = "max 9 control planes and 229 workers per node pool"
  }
}
