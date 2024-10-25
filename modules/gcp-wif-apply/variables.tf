variable "identities" {
  type = object({
    MODULE_NAME = string
    ids         = object({ oidc_bucket = string })
  })
  description = "gcp-wif module outputs"
  validation {
    condition     = var.identities.MODULE_NAME == "gcp-wif"
    error_message = "must be of type gcp-wif"
  }
}
variable "cluster" {
  type = object({
    MODULE_NAME      = string
    cluster_endpoint = string
  })
  description = "talos-cluster module outputs"
  validation {
    condition     = var.cluster.MODULE_NAME == "talos-cluster"
    error_message = "must be of type talos-cluster"
  }
}
variable "apply" {
  type = object({
    MODULE_NAME        = string
    ca_certificate     = string
    client_certificate = string
    client_key         = string
  })
  description = "talos-apply module outputs"
  validation {
    condition     = var.apply.MODULE_NAME == "talos-apply"
    error_message = "must be of type talos-apply"
  }
}
