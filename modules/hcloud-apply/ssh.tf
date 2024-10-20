resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}
resource "hcloud_ssh_key" "this" {
  name       = var.pool.prefix
  public_key = tls_private_key.ssh_key.public_key_openssh
}
