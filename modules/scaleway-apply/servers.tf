resource "scaleway_instance_server" "this" {
  for_each              = var.pool.nodes
  name                  = each.value.name
  image                 = each.value.image
  type                  = each.value.type
  zone                  = var.pool.zone
  user_data             = { cloud-init = var.cluster.configs[each.key] }
  placement_group_id    = var.pool.ids.group
  protected             = false
  security_group_id     = scaleway_instance_security_group.this.id
  ip_ids                = [var.pool.ids.ips.v6[each.key]]
  additional_volume_ids = [scaleway_instance_volume.ephemeral[each.key].id]

  lifecycle {
    ignore_changes = [image, user_data]
  }
}

resource "scaleway_instance_volume" "ephemeral" {
  for_each   = var.pool.nodes
  name       = "${each.value.name}-ephemeral"
  zone       = var.pool.zone
  type       = "l_ssd"
  size_in_gb = 25
}
