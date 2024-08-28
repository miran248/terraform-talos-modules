resource "hcloud_network" "this" {
  name     = var.pool.prefix
  ip_range = var.layout.cidrs4.network

  delete_protection = false
}
resource "hcloud_network_subnet" "machines" {
  network_id   = hcloud_network.this.id
  network_zone = var.location.network_zone
  ip_range     = var.layout.cidrs4.machines
  type         = "cloud"
}
# resource "hcloud_network_subnet" "services" {
#   network_id   = hcloud_network.this.id
#   network_zone = var.location.network_zone
#   ip_range     = var.layout.cidrs4.services
#   type         = "cloud"
# }
# resource "hcloud_network_subnet" "pods" {
#   network_id   = hcloud_network.this.id
#   network_zone = var.location.network_zone
#   ip_range     = var.layout.cidrs4.pods
#   type         = "cloud"
# }
