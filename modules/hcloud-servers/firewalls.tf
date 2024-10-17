resource "hcloud_firewall" "deny_all" {
  name = "${var.pool.prefix}-deny-all"
}

# TODO: extract from module and open ports required by cilium
resource "hcloud_firewall" "this" {
  name = var.pool.prefix

  rule {
    description = "apiserver"
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    source_ips = [
      "::/0",
      "0.0.0.0/0",
    ]
    destination_ips = var.cluster.features.ip6 ? [for key, node in var.config.nodes : node.public_ip6] : null
  }
  rule {
    description = "talos control planes"
    direction   = "in"
    protocol    = "tcp"
    port        = "50000"
    source_ips = [
      "::/0",
      "0.0.0.0/0",
    ]
    destination_ips = var.cluster.features.ip6 ? [for key, node in var.config.nodes : node.public_ip6] : null
  }
  rule {
    description = "talos workers"
    direction   = "in"
    protocol    = "tcp"
    port        = "50001"
    source_ips = [
      "::/0",
      "0.0.0.0/0",
    ]
    destination_ips = var.cluster.features.ip6 ? [for key, node in var.config.nodes : node.public_ip6] : null
  }
}
