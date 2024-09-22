provider "google" {
  project     = "sh-248-sandbox"
  credentials = var.google_token
}
provider "hcloud" {
  token = var.hcloud_token
}
provider "tfe" {
  organization = "miran248"
  token        = var.tfe_token
}
