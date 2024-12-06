
module "gcp_wif" {
  source = "../modules/gcp-wif"

  name            = "talos"
  bucket_name     = "miran248-talos-modules-dev-wif"
  bucket_location = "EUROPE-WEST3"

  service_accounts = [
    { subject = "cert-manager:cert-manager", name = "cert-manager", roles = ["roles/dns.admin"] },
    { subject = "external-dns:external-dns", name = "external-dns", roles = ["roles/dns.admin"] },

    { subject = "external-secrets:external-secrets", name = "external-secrets", roles = [
      "roles/iam.serviceAccountTokenCreator",
      "roles/secretmanager.admin",
      # "roles/secretmanager.secretAccessor",
    ] },
  ]
}
