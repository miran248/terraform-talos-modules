resource "hcloud_server" "this" {
  for_each    = var.network.nodes
  name        = var.config.nodes[each.key].name
  image       = var.image_id
  server_type = var.config.nodes[each.key].server_type
  datacenter  = var.datacenter.name
  user_data   = var.config.nodes[each.key].data
  ssh_keys    = [hcloud_ssh_key.this.id]

  delete_protection        = false
  shutdown_before_deletion = true

  ignore_remote_firewall_ids = true
  firewall_ids = [
    hcloud_firewall.deny_all.id,
  ]

  public_net {
    ipv6_enabled = true
    ipv6         = var.network.ids.ips6[each.key]
    ipv4_enabled = false
  }

  lifecycle {
    ignore_changes = [
      image,
      user_data,
    ]
  }
}

resource "hcloud_firewall_attachment" "this" {
  firewall_id = hcloud_firewall.this.id
  server_ids  = [for key, server in hcloud_server.this : server.id]
}
