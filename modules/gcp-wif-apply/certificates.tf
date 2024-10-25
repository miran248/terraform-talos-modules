resource "local_sensitive_file" "ca_certificate" {
  filename = "${path.module}/ca_certificate"
  content  = var.apply.ca_certificate
}
resource "local_sensitive_file" "client_certificate" {
  filename = "${path.module}/client_certificate"
  content  = var.apply.client_certificate
}
resource "local_sensitive_file" "client_key" {
  filename = "${path.module}/client_key"
  content  = var.apply.client_key
}
