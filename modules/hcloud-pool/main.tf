# ips
resource "hcloud_primary_ip" "ips6" {
  for_each      = local.s2.nodes
  name          = "${each.value.name}-ip6"
  location      = var.location
  type          = "ipv6"
  assignee_type = "server"
  auto_delete   = false

  delete_protection = false
}

# placement groups
resource "hcloud_placement_group" "this" {
  name = var.prefix
  type = "spread"
}
