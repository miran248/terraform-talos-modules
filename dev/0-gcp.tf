# dns
data "google_dns_managed_zone" "this" {
  name = "dev"
}

# secrets
data "google_secret_manager_secret_version" "hcloud_token" {
  secret = "hcloud"
}
