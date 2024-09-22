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
    source_ips = [
      "::/0",
      "0.0.0.0/0",
    ]
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
  }

  # rule {
  #   description = "allows pings"
  #   direction = "in"
  #   protocol  = "icmp"
  #   source_ips = [
  #     "::/0",
  #     "0.0.0.0/0",
  #   ]
  # }
}
