variable "cluster" {
  type = object({
    endpoint = string
  })
  description = "cluster config module outputs"
}
variable "config" {
  type = object({
    machine_secrets = object({
      client_configuration = object({ ca_certificate = string, client_certificate = string, client_key = string })
    })
    private_ips4 = object({
      control_planes = list(string)
      workers        = list(string)
    })
    nodes = map(object({
      name = string
      data = string
    }))
  })
  description = "talos config module outputs"
}
