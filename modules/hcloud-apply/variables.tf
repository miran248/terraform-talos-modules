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
    datacenter  = string
    nodes = map(object({
      name                  = string
      server_type           = string
      image_id              = number
      public_ip6_id         = number
      public_ip6_network_64 = string
      public_ip6            = string
    }))
  })
  description = "hcloud-pool module outputs"
  validation {
    condition     = var.pool.MODULE_NAME == "hcloud-pool"
    error_message = "must be of type hcloud-pool"
  }
}
