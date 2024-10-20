resource "hcloud_primary_ip" "ips6" {
  for_each      = local.s2.nodes
  name          = "${each.value.name}-ip6"
  datacenter    = var.datacenter
  type          = "ipv6"
  assignee_type = "server"
  auto_delete   = false

  delete_protection = false
}
