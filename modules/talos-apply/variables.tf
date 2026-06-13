variable "cluster" {
  type = object({
    MODULE_NAME        = string
    name               = string
    endpoint           = string
    cluster_endpoint   = string
    talos_version      = string
    kubernetes_version = string
    machine_secrets = object({
      client_configuration = object({ ca_certificate = string, client_certificate = string, client_key = string })
      machine_secrets      = any
    })
    nodes = map(object({
      kind    = string
      aliases = list(string)
      patches = list(string)
      talos   = object({ machine_type = string })
    }))
  })
  description = "talos-cluster module outputs"
  validation {
    condition     = var.cluster.MODULE_NAME == "talos-cluster"
    error_message = "must be of type talos-cluster"
  }
}

variable "installer_image" {
  type        = string
  default     = null
  description = "Talos installer image for OS version management via talos_machine. Defaults to ghcr.io/siderolabs/installer:<talos_version>. Override for dev builds or custom schematics."
}

variable "applies" {
  type = list(object({
    ips = object({
      v6 = map(string)
    })
  }))
  description = "apply module outputs to collect actual node IPs for host entries and control plane health checks"
}
