locals {
  any_cidr = var.pool.mode == "ipv6" ? "::/0" : "0.0.0.0/0"

  nodes = { for key, node in var.pool.nodes : key => merge(node, {
    ip = cidrhost(node.ip_cidr, var.pool.mode == "ipv6" ? 1 : 0)
  }) }
}

resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}
resource "hcloud_ssh_key" "this" {
  name       = var.pool.prefix
  public_key = tls_private_key.ssh_key.public_key_openssh
}

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
    source_ips  = [local.any_cidr]
  }
  rule {
    description = "talos apid"
    direction   = "in"
    protocol    = "tcp"
    port        = "50000"
    source_ips  = [local.any_cidr]
  }
  rule {
    description = "talos trustd"
    direction   = "in"
    protocol    = "tcp"
    port        = "50001"
    source_ips  = [local.any_cidr]
  }
  # full intra-cluster access across all pools
  dynamic "rule" {
    for_each = toset(["tcp", "udp"])
    content {
      direction  = "in"
      protocol   = rule.value
      port       = "any"
      source_ips = [for _, node in var.cluster.nodes : node.ip_cidr]
    }
  }
  dynamic "rule" {
    for_each = toset(["icmp", "gre", "esp"])
    content {
      direction  = "in"
      protocol   = rule.value
      source_ips = [for _, node in var.cluster.nodes : node.ip_cidr]
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

resource "hcloud_server" "this" {
  for_each                 = var.pool.nodes
  name                     = each.value.name
  image                    = each.value.image
  server_type              = each.value.server_type
  location                 = var.pool.location
  user_data                = var.cluster.configs[each.key]
  placement_group_id       = var.pool.ids.group
  delete_protection        = false
  shutdown_before_deletion = true

  ssh_keys = [
    hcloud_ssh_key.this.id,
  ]

  ignore_remote_firewall_ids = true
  firewall_ids = [
    hcloud_firewall.deny_all.id,
  ]

  public_net {
    ipv6_enabled = var.pool.mode == "ipv6"
    ipv6         = var.pool.mode == "ipv6" ? var.pool.ids.ips[each.key] : null
    ipv4_enabled = var.pool.mode == "ipv4"
    ipv4         = var.pool.mode == "ipv4" ? var.pool.ids.ips[each.key] : null
  }

  lifecycle {
    ignore_changes = [image, user_data]
  }
}

resource "hcloud_firewall_attachment" "this" {
  firewall_id = hcloud_firewall.this.id
  server_ids  = [for _, s in hcloud_server.this : s.id]
}
