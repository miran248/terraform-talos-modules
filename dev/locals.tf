locals {
  hcloud_token   = data.google_secret_manager_secret_version.hcloud_token.secret_data
  scaleway_token = jsondecode(data.google_secret_manager_secret_version.scaleway_token.secret_data)
}
