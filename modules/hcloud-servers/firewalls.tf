resource "hcloud_firewall" "deny_all" {
  name = "${var.pool.prefix}-deny-all"
}

resource "hcloud_firewall" "this" {
  name = var.pool.prefix

  rule {
    description     = "apiserver"
    direction       = "in"
    protocol        = "tcp"
    port            = "6443"
    source_ips      = ["::/0"]
    destination_ips = [for key, node in var.config.nodes : node.public_ip6]
  }
  rule {
    description     = "talos control planes"
    direction       = "in"
    protocol        = "tcp"
    port            = "50000"
    source_ips      = ["::/0"]
    destination_ips = [for key, node in var.config.nodes : node.public_ip6]
  }
  rule {
    description     = "talos workers"
    direction       = "in"
    protocol        = "tcp"
    port            = "50001"
    source_ips      = ["::/0"]
    destination_ips = [for key, node in var.config.nodes : node.public_ip6]
  }

  # allows full access between cluster nodes
  dynamic "rule" {
    for_each = toset(["tcp", "udp"])
    content {
      direction       = "in"
      protocol        = rule.value
      port            = "any"
      source_ips      = [for key, node in var.config.nodes : node.public_ip6_network_64]
      destination_ips = [for key, node in var.config.nodes : node.public_ip6_network_64]
    }
  }
  dynamic "rule" {
    for_each = toset(["icmp", "gre", "esp"])
    content {
      direction       = "in"
      protocol        = rule.value
      source_ips      = [for key, node in var.config.nodes : node.public_ip6_network_64]
      destination_ips = [for key, node in var.config.nodes : node.public_ip6_network_64]
    }
  }
}
