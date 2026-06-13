locals {
  nodes = { for key, _ in var.pool.nodes :
    key => merge(var.pool.nodes[key], {
      ip = [for pip in scaleway_instance_server.this[key].public_ips :
        pip.address if pip.id == var.pool.ids.ips.v6[key]
      ][0]
    })
  }
}

resource "scaleway_instance_security_group" "this" {
  name                    = var.pool.prefix
  zone                    = var.pool.zone
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"
  stateful                = true
  enable_default_security = true

  # kubernetes apiserver - only opened when pool contains control planes
  dynamic "inbound_rule" {
    for_each = anytrue([for n in var.pool.nodes : n.kind == "control-plane"]) ? [1] : []
    content {
      action   = "accept"
      protocol = "TCP"
      port     = "6443"
    }
  }
  # talos apid - opened on all nodes
  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = "50000"
  }
  # talos trustd - only opened when pool contains control planes
  dynamic "inbound_rule" {
    for_each = anytrue([for n in var.pool.nodes : n.kind == "control-plane"]) ? [1] : []
    content {
      action   = "accept"
      protocol = "TCP"
      port     = "50001"
    }
  }

  # full intra-cluster access across all pools
  dynamic "inbound_rule" {
    for_each = var.cluster.nodes
    content {
      action   = "accept"
      protocol = "ANY"
      ip_range = inbound_rule.value.ip_64
    }
  }

  # additional rules (e.g. http/https for ingress)
  dynamic "inbound_rule" {
    for_each = var.inbound_rules
    content {
      action     = inbound_rule.value.action
      protocol   = inbound_rule.value.protocol
      port       = inbound_rule.value.port
      port_range = inbound_rule.value.port_range
      ip_range   = inbound_rule.value.ip_range
    }
  }
}

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
