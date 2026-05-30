variable "pool" {
  type = object({
    MODULE_NAME = string
    prefix      = string
    zone        = string
    nodes = map(object({
      kind  = string
      name  = string
      type  = string
      image = string
    }))
    ids = object({
      group = string
      ips   = object({ v6 = map(string), v4 = map(string) })
    })
  })
  description = "scaleway-pool module outputs"
  validation {
    condition     = var.pool.MODULE_NAME == "scaleway-pool"
    error_message = "must be of type scaleway-pool"
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
