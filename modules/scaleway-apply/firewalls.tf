resource "scaleway_instance_security_group" "this" {
  name                    = var.pool.prefix
  zone                    = var.pool.zone
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"
  stateful                = true
  enable_default_security = true

  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = "6443"
  }
  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = "50000"
  }
  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = "50001"
  }
  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = "443"
  }
  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = "80"
  }
  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = "10256"
  }

  # allows full access between cluster nodes
  dynamic "inbound_rule" {
    for_each = var.cluster.nodes
    content {
      action   = "accept"
      protocol = "ANY"
      ip_range = inbound_rule.value.public_ip6_network_64
    }
  }
}
