resource "hcloud_server" "this" {
  for_each                 = var.pool.nodes
  name                     = var.pool.nodes[each.key].name
  image                    = var.pool.nodes[each.key].image
  server_type              = var.pool.nodes[each.key].server_type
  location                 = var.pool.location
  user_data                = var.cluster.configs[each.key]
  placement_group_id       = var.pool.ids.group
  delete_protection        = false
  shutdown_before_deletion = true

  ssh_keys = [
    hcloud_ssh_key.this.id,
  ]

  ignore_remote_firewall_ids = true
  firewall_ids = [
    hcloud_firewall.deny_all.id,
  ]

  public_net {
    ipv6_enabled = true
    ipv6         = var.pool.nodes[each.key].public_ip6_id
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
