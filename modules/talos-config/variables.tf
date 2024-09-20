variable "cluster" {
  type = object({
    name             = string
    endpoint         = string
    cluster_endpoint = string
  })
  description = "cluster config module outputs"
}
variable "networks" {
  type = list(object({
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
      public_ip6_network_128 = optional(string, null)
      public_ip6_network_64  = optional(string, null)
      public_ip6_128         = optional(string, null)
      public_ip6_64          = optional(string, null)
      public_ip6             = optional(string, null)
      public_ip4_32          = optional(string, null)
      public_ip4             = optional(string, null)
      talos                  = object({ machine_type = string })
      patches                = list(string)
    }))
  }))
  description = "list of network module outputs"
}

variable "talos_version" {
  type        = string
  description = "talos version"
}
variable "kubernetes_version" {
  type        = string
  description = "kubernetes version"
}
