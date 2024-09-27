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

  # ignore_remote_firewall_ids = true
  # firewall_ids = [
  #   var.network.ids.firewall_deny_all,
  # ]

  public_net {
    ipv6_enabled = var.cluster.features.ip6
    ipv6         = var.cluster.features.ip6 ? var.network.ids.ips6[each.key] : null
    ipv4_enabled = var.cluster.features.ip4
    ipv4         = var.cluster.features.ip4 ? var.network.ids.ips4[each.key] : null
  }

  network {
    network_id = var.network.ids.network
    ip         = var.config.nodes[each.key].private_ip4
    alias_ips  = []
  }

  lifecycle {
    ignore_changes = [
      image,
      user_data,
    ]
  }
}

# resource "hcloud_firewall_attachment" "this" {
#   firewall_id = var.network.ids.firewall
#   server_ids  = [for key, server in hcloud_server.this : server.id]
# }
