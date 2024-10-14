# resource "hcloud_network" "this" {
#   name     = "${var.pool.prefix}-cilium"
#   ip_range = "10.0.0.0/8"

#   delete_protection = false
# }
# resource "hcloud_network_subnet" "services" {
#   network_id   = hcloud_network.this.id
#   network_zone = var.location.network_zone
#   ip_range     = "10.0.0.0/12"
#   type         = "cloud"
# }
# resource "hcloud_network_subnet" "pods" {
#   network_id   = hcloud_network.this.id
#   network_zone = var.location.network_zone
#   ip_range     = "10.16.0.0/12"
#   type         = "cloud"
# }
