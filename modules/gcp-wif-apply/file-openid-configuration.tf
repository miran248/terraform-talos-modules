data "terracurl_request" "openid_configuration" {
  name   = "openid-configuration"
  url    = "${var.cluster.cluster_endpoint}/.well-known/openid-configuration"
  method = "GET"

  ca_cert_file    = local_sensitive_file.ca_certificate.filename
  cert_file       = local_sensitive_file.client_certificate.filename
  key_file        = local_sensitive_file.client_key.filename
  skip_tls_verify = false

  response_codes = [200]
}

resource "terraform_data" "openid_configuration" {
  input = timestamp()
}
resource "google_storage_bucket_object" "openid_configuration" {
  bucket        = var.identities.ids.oidc_bucket
  name          = ".well-known/openid-configuration"
  content       = data.terracurl_request.openid_configuration.response
  cache_control = "public, max-age=0"
  content_type  = "application/json"

  lifecycle {
    replace_triggered_by = [
      terraform_data.openid_configuration,
    ]
  }
}
