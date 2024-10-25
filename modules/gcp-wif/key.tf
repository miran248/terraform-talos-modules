resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
