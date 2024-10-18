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

variable "pool" {
  type = object({
    prefix = string
    nodes = map(object({
      name        = string
      server_type = string
      talos       = object({ machine_type = string })
      patches     = list(string)
    }))
  })
  description = "node pool module outputs"
}
