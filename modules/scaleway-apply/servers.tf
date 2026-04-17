resource "scaleway_instance_server" "this" {
  for_each           = var.pool.nodes
  name               = var.pool.nodes[each.key].name
  image              = var.pool.nodes[each.key].image
  type               = var.pool.nodes[each.key].type
  zone               = var.pool.zone
  user_data          = { cloud-init = var.cluster.configs[each.key] }
  placement_group_id = var.pool.ids.group
  protected          = false
  security_group_id  = scaleway_instance_security_group.this.id
  ip_id              = var.pool.nodes[each.key].public_ip6_id

  lifecycle {
    ignore_changes = [
      image,
      user_data,
    ]
  }
}
