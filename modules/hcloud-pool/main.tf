# ips
resource "hcloud_primary_ip" "this" {
  for_each    = local.s1
  name        = each.key
  location    = var.location
  type        = "ipv6"
  auto_delete = false

  delete_protection = false
}

# placement groups
resource "hcloud_placement_group" "this" {
  name = var.prefix
  type = "spread"
}
