variable "prefix" {
  type        = string
  description = "hcloud resource name prefix, must be unique"
}
variable "location" {
  type        = string
  description = "hcloud location"
}

variable "control_planes" {
  type = list(object({
    server_type = string
    image       = number
    aliases     = optional(list(string), [])
    patches     = optional(list(string), [])
    removed     = optional(bool, false)
  }))
  description = "define control planes"
  default     = []
}
variable "workers" {
  type = list(object({
    server_type = string
    image       = number
    aliases     = optional(list(string), [])
    patches     = optional(list(string), [])
    removed     = optional(bool, false)
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
