resource "hcloud_primary_ip" "ips6" {
  for_each      = var.pool.nodes
  name          = "${each.value.name}-ip6"
  datacenter    = var.datacenter.name
  type          = "ipv6"
  assignee_type = "server"
  auto_delete   = false

  delete_protection = false
}
