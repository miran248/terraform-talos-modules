# ips
resource "scaleway_instance_ip" "this" {
  for_each = local.s2
  zone     = var.zone
  type     = "routed_ipv6"
}

# placement groups
resource "scaleway_instance_placement_group" "this" {
  name        = var.prefix
  policy_type = "max_availability"
  # policy_mode = "enforced"
  policy_mode = "optional"
  zone        = var.zone
}
