resource "hcloud_primary_ip" "ips6" {
  for_each      = var.cluster.features.ip6 ? var.pool.nodes : {}
  name          = "${each.value.name}-ip6"
  datacenter    = var.datacenter.name
  type          = "ipv6"
  assignee_type = "server"
  auto_delete   = false

  delete_protection = false
}
resource "hcloud_primary_ip" "ips4" {
  for_each      = var.cluster.features.ip4 ? var.pool.nodes : {}
  name          = "${each.value.name}-ip4"
  datacenter    = var.datacenter.name
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = false

  delete_protection = false
}
