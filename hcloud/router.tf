resource "hcloud_primary_ip" "router_ipv4" {
  count         = var.router == null ? 0 : 1
  name          = "${var.pool.names.router}-ipv4"
  datacenter    = var.datacenter.name
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = false

  delete_protection = false
}
resource "hcloud_server" "router" {
  count       = var.router == null ? 0 : 1
  name        = var.pool.names.router
  image       = "debian-12"
  server_type = "cx22"
  datacenter  = var.datacenter.name
  user_data   = var.router

  delete_protection        = false
  shutdown_before_deletion = true

  labels = {
    "role" = "router"
  }

  ignore_remote_firewall_ids = true
  firewall_ids = [
    hcloud_firewall.deny_all[0].id,
  ]

  public_net {
    ipv4_enabled = true
    ipv4         = hcloud_primary_ip.router_ipv4[0].id
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.this.id
    ip         = var.zone.ips4.router
  }
}
resource "hcloud_network_route" "public" {
  count       = var.router == null ? 0 : 1
  network_id  = hcloud_network.this.id
  destination = "0.0.0.0/0"
  gateway     = var.zone.ips4.router
}
