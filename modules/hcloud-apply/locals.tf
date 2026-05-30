locals {
  ips = {
    v6 = { for key, node in var.pool.nodes : key => cidrhost(node.ip_64, 1) }
  }
}
