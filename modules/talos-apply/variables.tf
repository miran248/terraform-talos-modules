variable "cluster" {
  type = object({
    endpoint = string
    machine_secrets = object({
      client_configuration = object({ ca_certificate = string, client_certificate = string, client_key = string })
    })
    names = object({
      control_planes = list(string)
      workers        = list(string)
    })
    configs = map(string)
  })
  description = "talos-cluster module outputs"
}
