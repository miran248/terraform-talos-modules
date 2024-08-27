resource "hcloud_firewall" "deny_all" {
  count = var.router == null ? 0 : 1
  name  = "${var.pool.prefix}-deny-all"
}
resource "hcloud_firewall_attachment" "deny_all" {
  count       = var.router == null ? 0 : 1
  firewall_id = hcloud_firewall.deny_all[0].id

  server_ids = [
    hcloud_server.router[0].id,
  ]
}
