# from google variable set
variable "google_token" {
  sensitive = true
  type      = string
}

# from hetzner variable set
variable "hcloud_token" {
  sensitive = true
  type      = string
}

# from tfe variable set
variable "tfe_token" {
  sensitive = true
  type      = string
}
