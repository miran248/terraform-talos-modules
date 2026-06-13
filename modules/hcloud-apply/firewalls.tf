resource "hcloud_firewall" "deny_all" {
  name = "${var.pool.prefix}-deny-all"
}

resource "hcloud_firewall" "this" {
  name = var.pool.prefix

  # kubernetes apiserver - only opened when pool contains control planes
  dynamic "rule" {
    for_each = anytrue([for n in var.pool.nodes : n.kind == "control-plane"]) ? [1] : []
    content {
      description = "apiserver"
      direction   = "in"
      protocol    = "tcp"
      port        = "6443"
      source_ips  = ["::/0"]
    }
  }
  # talos apid - opened on all nodes
  rule {
    description = "talos apid"
    direction   = "in"
    protocol    = "tcp"
    port        = "50000"
    source_ips  = ["::/0"]
  }
  # talos trustd - only opened when pool contains control planes
  dynamic "rule" {
    for_each = anytrue([for n in var.pool.nodes : n.kind == "control-plane"]) ? [1] : []
    content {
      description = "talos trustd"
      direction   = "in"
      protocol    = "tcp"
      port        = "50001"
      source_ips  = ["::/0"]
    }
  }

  # full intra-cluster access across all pools
  dynamic "rule" {
    for_each = toset(["tcp", "udp"])
    content {
      direction  = "in"
      protocol   = rule.value
      port       = "any"
      source_ips = [for _, node in var.cluster.nodes : node.ip_64]
    }
  }
  dynamic "rule" {
    for_each = toset(["icmp", "gre", "esp"])
    content {
      direction  = "in"
      protocol   = rule.value
      source_ips = [for _, node in var.cluster.nodes : node.ip_64]
    }
  }

  # additional rules (e.g. http/https for ingress)
  dynamic "rule" {
    for_each = var.rules
    content {
      description     = rule.value.description
      direction       = rule.value.direction
      protocol        = rule.value.protocol
      port            = rule.value.port
      source_ips      = rule.value.source_ips
      destination_ips = rule.value.destination_ips
    }
  }
}
