locals {
  # Local module instances share path.module; isolate each cluster's TLS files.
  credentials_directory = "${path.root}/.terraform/gcp-wif-apply/${sha256(var.cluster.cluster_endpoint)}"
}

resource "local_sensitive_file" "ca_certificate" {
  filename             = "${local.credentials_directory}/ca_certificate"
  content              = var.apply.ca_certificate
  file_permission      = "0600"
  directory_permission = "0700"
}
resource "local_sensitive_file" "client_certificate" {
  filename             = "${local.credentials_directory}/client_certificate"
  content              = var.apply.client_certificate
  file_permission      = "0600"
  directory_permission = "0700"
}
resource "local_sensitive_file" "client_key" {
  filename             = "${local.credentials_directory}/client_key"
  content              = var.apply.client_key
  file_permission      = "0600"
  directory_permission = "0700"
}

data "terracurl_request" "jwks" {
  name   = "jwks"
  url    = "${var.cluster.cluster_endpoint}/openid/v1/jwks"
  method = "GET"

  ca_cert_file    = local_sensitive_file.ca_certificate.filename
  cert_file       = local_sensitive_file.client_certificate.filename
  key_file        = local_sensitive_file.client_key.filename
  skip_tls_verify = false

  response_codes = [200]
  # Bootstrap can finish before the Kubernetes API/load balancer accepts TLS.
  max_retry      = 30
  retry_interval = 5
  timeout        = 10
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

data "terracurl_request" "openid_configuration" {
  name   = "openid-configuration"
  url    = "${var.cluster.cluster_endpoint}/.well-known/openid-configuration"
  method = "GET"

  ca_cert_file    = local_sensitive_file.ca_certificate.filename
  cert_file       = local_sensitive_file.client_certificate.filename
  key_file        = local_sensitive_file.client_key.filename
  skip_tls_verify = false

  response_codes = [200]
  max_retry      = 30
  retry_interval = 5
  timeout        = 10
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
