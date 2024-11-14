provider "google" {
  project = "miran248-talos-modules-dev"
  region  = "global"
}
provider "hcloud" {
  token = local.hcloud_token
}
