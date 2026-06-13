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
