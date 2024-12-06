resource "hcloud_firewall" "deny_all" {
  name = "${var.pool.prefix}-deny-all"
}

resource "hcloud_firewall" "this" {
  name = var.pool.prefix

  rule {
    description = "apiserver"
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    source_ips  = ["::/0"]
  }
  rule {
    description = "talos control planes"
    direction   = "in"
    protocol    = "tcp"
    port        = "50000"
    source_ips  = ["::/0"]
  }
  rule {
    description = "talos workers"
    direction   = "in"
    protocol    = "tcp"
    port        = "50001"
    source_ips  = ["::/0"]
  }
  rule {
    description = "https"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips  = ["::/0"]
  }
  rule {
    description = "http"
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips  = ["::/0"]
  }
  rule {
    description = "healthz"
    direction   = "in"
    protocol    = "tcp"
    port        = "10256"
    source_ips  = ["::/0"]
  }

  # allows full access between cluster nodes
  dynamic "rule" {
    for_each = toset(["tcp", "udp"])
    content {
      direction  = "in"
      protocol   = rule.value
      port       = "any"
      source_ips = [for key, node in var.cluster.nodes : node.public_ip6_network_64]
    }
  }
  dynamic "rule" {
    for_each = toset(["icmp", "gre", "esp"])
    content {
      direction  = "in"
      protocol   = rule.value
      source_ips = [for key, node in var.cluster.nodes : node.public_ip6_network_64]
    }
  }
}
