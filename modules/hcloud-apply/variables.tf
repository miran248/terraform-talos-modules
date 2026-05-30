variable "pool" {
  type = object({
    MODULE_NAME = string
    prefix      = string
    location    = string
    nodes = map(object({
      kind        = string
      name        = string
      server_type = string
      image       = number
      ip_64       = string
    }))
    ids = object({
      group = number
      ips   = object({ v6 = map(number) })
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
    nodes       = map(object({ ip_64 = string }))
    configs     = map(string)
  })
  description = "talos-cluster module outputs"
  validation {
    condition     = var.cluster.MODULE_NAME == "talos-cluster"
    error_message = "must be of type talos-cluster"
  }
}
