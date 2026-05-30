provider "google" {
  project = "miran248-talos-modules-dev"
  region  = "global"
}
provider "hcloud" {
  token = local.hcloud_token
}
provider "scaleway" {
  organization_id = local.scaleway_token.organization_id
  project_id      = local.scaleway_token.project_id
  access_key      = local.scaleway_token.access_key
  secret_key      = local.scaleway_token.secret_key
}
