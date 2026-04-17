variable "cluster" {
  type = object({
    nodes = map(object({
      public_ip6_network_64 = string
    }))
    configs = map(string)
  })
  description = "talos-cluster module outputs"
}
variable "pool" {
  type = object({
    MODULE_NAME = string
    prefix      = string
    zone        = string
    ids = object({
      group = string
    })
    nodes = map(object({
      name                  = string
      type                  = string
      image                 = string
      public_ip6_id         = string
      public_ip6_network_64 = string
      public_ip6            = string
    }))
  })
  description = "scaleway-pool module outputs"
  validation {
    condition     = var.pool.MODULE_NAME == "scaleway-pool"
    error_message = "must be of type scaleway-pool"
  }
}
