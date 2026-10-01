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
variable "applies" {
  type = list(object({
    nodes = map(object({
      kind = string
      ip   = string
    }))
  }))
  description = "list of apply module outputs (e.g. hcloud-apply, scaleway-apply)"
}

variable "drain_on_upgrade" {
  type        = bool
  default     = true
  description = "drain nodes before upgrading"
}

variable "installer_image" {
  type        = string
  default     = null
  description = "Optional Talos installer image for OS version management via talos_machine, such as a custom image or dev build. When null, the installed OS version is not managed."
}
