variable "datacenter" {
  type = object({
    name = string
  })
  description = "zone datacenter"
}
variable "location" {
  type = object({
    network_zone = string
  })
  description = "zone location"
}

variable "cluster" {
  type = object({
    features = object({
      ip6 = optional(bool, false)
      ip4 = optional(bool, false)
    })
  })
  description = "cluster config module outputs"
}
variable "pool" {
  type = object({
    prefix = string
    cidrs4 = object({ machines = string })
    nodes = map(object({
      name                   = string
      server_type            = string
      private_ip4_network_24 = string
      private_ip4_gateway_32 = string
      private_ip4_gateway_24 = string
      private_ip4_gateway    = string
      private_ip4_32         = string
      private_ip4_24         = string
      private_ip4            = string
      talos                  = object({ machine_type = string })
      patches                = list(string)
    }))
  })
  description = "node pool module outputs"
}
