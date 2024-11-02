variable "prefix" {
  type        = string
  description = "hcloud resource name prefix, must be unique"
}
variable "datacenter" {
  type        = string
  description = "hcloud datacenter"
}

variable "cidr" {
  type        = string
  description = "hcloud private network cidr4"
  nullable    = true
  default     = null
}
variable "load_balancer_ip" {
  type        = string
  description = "hcloud load balancer ip4"
  nullable    = true
  default     = null
}

variable "control_planes" {
  type = list(object({
    server_type = string
    image_id    = number
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
    image_id    = number
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
