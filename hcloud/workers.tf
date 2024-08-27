resource "hcloud_server" "workers" {
  for_each    = var.pool.workers
  name        = each.value.name
  image       = var.image_id
  server_type = each.value.server_type
  datacenter  = var.datacenter.name
  user_data   = var.config.workers[each.key].machine_configuration

  delete_protection        = false
  shutdown_before_deletion = true

  labels = each.value.node_labels

  public_net {
    ipv4_enabled = false
    ipv6_enabled = false
  }

  network {
    network_id = hcloud_network.this.id
    ip         = each.key
  }

  lifecycle {
    ignore_changes = [
      image,
      user_data,
    ]
  }

  depends_on = [
    hcloud_network.this,
    hcloud_network_subnet.machines,
  ]
}
