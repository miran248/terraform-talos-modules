resource "hcloud_server" "router_client" {
  count       = var.router_client == null ? 0 : 1
  name        = var.pool.names.router_client
  image       = "debian-12"
  server_type = "cx22"
  datacenter  = var.datacenter.name
  user_data   = var.router_client

  delete_protection        = false
  shutdown_before_deletion = true

  labels = {
    "role" = "router-client"
  }

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.this.id
    ip         = var.zone.ips4.router_client
  }
}
