variable "pool" {
  type = object({
    MODULE_NAME = string
    prefix      = string
    location    = string
    mode        = string
    nodes = map(object({
      kind        = string
      name        = string
      server_type = string
      image       = number
      ip_cidr     = string
    }))
    ids = object({
      group = number
      ips   = map(number)
    })
  })
  description = "hcloud-pool module outputs"
  validation {
    condition     = var.pool.MODULE_NAME == "hcloud-pool"
    error_message = "must be of type hcloud-pool"
  }
}
variable "cluster" {
  type = object({
    MODULE_NAME = string
    nodes       = map(object({ ip_cidr = string }))
    configs     = map(string)
  })
  description = "talos-cluster module outputs"
  validation {
    condition     = var.cluster.MODULE_NAME == "talos-cluster"
    error_message = "must be of type talos-cluster"
  }
}

variable "rules" {
  type = list(object({
    description     = optional(string)
    direction       = string
    protocol        = string
    port            = optional(string)
    source_ips      = optional(list(string), [])
    destination_ips = optional(list(string), [])
  }))
  default     = []
  description = "Additional firewall rules to add to the pool firewall."
}
