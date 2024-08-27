variable "config" {
  type = object({
    cluster_name = string
    endpoint     = string

    machine_secrets = object({
      client_configuration = object({ ca_certificate = string, client_certificate = string, client_key = string })
    })

    control_planes = map(object({ machine_configuration = string, patches = list(string) }))
    workers        = map(object({ machine_configuration = string, patches = list(string) }))
  })
  description = "talos config module outputs"
}
