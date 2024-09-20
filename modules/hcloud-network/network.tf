resource "hcloud_network" "this" {
  name     = var.pool.prefix
  ip_range = var.pool.cidrs4.machines

  delete_protection = false
}
resource "hcloud_network_subnet" "machines" {
  network_id   = hcloud_network.this.id
  network_zone = var.location.network_zone
  ip_range     = var.pool.cidrs4.machines
  type         = "cloud"
}
