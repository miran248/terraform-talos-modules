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

variable "layout" {
  type = object({
    cidrs4 = object({ network = string, machines = string, services = string, pods = string })
  })
  description = "network layout module outputs"
}

variable "zone" {
  type = object({
    ips4 = object({
      load_balancer  = string
      router         = string
      router_client  = string
      control_planes = list(string)
      workers        = list(string)
    })
    cloud  = number
    region = number
    zone   = number
  })
}
variable "pool" {
  type = object({
    prefix = string
    names = object({
      router        = string
      router_client = string
    })
    control_planes = map(object({
      name        = string
      server_type = string
      node_labels = map(any)
    }))
    workers = map(object({
      name        = string
      server_type = string
      node_labels = map(any)
    }))
  })
  description = "node pool module outputs"
}

variable "config" {
  type = object({
    control_planes = map(object({ machine_configuration = string }))
    workers        = map(object({ machine_configuration = string }))
  })
  description = "talos config module outputs"
}

variable "image_id" {
  type        = number
  description = "server image"
}

variable "router" {
  type        = string
  description = "router user data"
  default     = null
}
variable "router_client" {
  type        = string
  description = "router test client user data"
  default     = null
}
