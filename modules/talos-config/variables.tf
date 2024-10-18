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
      name                  = string
      server_type           = string
      public_ip6_network_64 = optional(string, null)
      public_ip6_64         = optional(string, null)
      public_ip6            = optional(string, null)
      talos                 = object({ machine_type = string })
      patches               = list(string)
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
