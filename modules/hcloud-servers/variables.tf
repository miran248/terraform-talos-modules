variable "datacenter" {
  type = object({
    name = string
  })
  description = "zone datacenter"
}
variable "location" {
  type = object({
    id           = number
    name         = string
    network_zone = string
  })
  description = "zone location"
}
variable "image_id" {
  type        = number
  description = "server image"
}

variable "pool" {
  type = object({
    prefix = string
  })
  description = "node pool module outputs"
}
variable "network" {
  type = object({
    ids = object({
      ips6 = map(number)
    })
    nodes = map(any)
  })
  description = "network module outputs"
}
variable "config" {
  type = object({
    nodes = map(object({
      name                  = string
      server_type           = string
      public_ip6_network_64 = optional(string, null)
      public_ip6            = optional(string, null)
      data                  = string
    }))
  })
  description = "talos config module outputs"
}
