data "terracurl_request" "jwks" {
  name   = "jwks"
  url    = "${var.cluster.cluster_endpoint}/openid/v1/jwks"
  method = "GET"

  ca_cert_file    = local_sensitive_file.ca_certificate.filename
  cert_file       = local_sensitive_file.client_certificate.filename
  key_file        = local_sensitive_file.client_key.filename
  skip_tls_verify = false

  response_codes = [200]
}

resource "terraform_data" "jwks" {
  input = timestamp()
}
resource "google_storage_bucket_object" "jwks" {
  bucket        = var.identities.ids.oidc_bucket
  name          = "openid/v1/jwks"
  content       = data.terracurl_request.jwks.response
  cache_control = "public, max-age=0"
  content_type  = "application/json"

  lifecycle {
    replace_triggered_by = [
      terraform_data.jwks,
    ]
  }
}
