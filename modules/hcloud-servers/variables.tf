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
  })
  description = "node pool module outputs"
}
variable "network" {
  type = object({
    ids = object({
      network  = number
      machines = string
      ips6     = map(number)
      ips4     = map(number)
    })
    nodes = map(any)
  })
  description = "network module outputs"
}
variable "config" {
  type = object({
    nodes = map(object({
      name        = string
      server_type = string
      public_ip6  = optional(string, null)
      public_ip4  = optional(string, null)
      private_ip4 = string
      data        = string
    }))
  })
  description = "talos config module outputs"
}
