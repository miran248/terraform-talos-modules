resource "hcloud_load_balancer" "this" {
  name               = var.pool.prefix
  load_balancer_type = "lb11"
  location           = var.location.name

  delete_protection = false

  algorithm {
    type = "round_robin"
  }
}
resource "hcloud_load_balancer_network" "machines" {
  load_balancer_id = hcloud_load_balancer.this.id
  subnet_id        = hcloud_network_subnet.machines.id
  ip               = var.zone.ips4.load_balancer

  enable_public_interface = true

  depends_on = [
    hcloud_network.this,
    hcloud_network_subnet.machines,
  ]
}

# load balancer services
resource "hcloud_load_balancer_service" "kubernetes" {
  load_balancer_id = hcloud_load_balancer.this.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
  proxyprotocol    = false
}
# resource "hcloud_load_balancer_service" "kubeprism" {
#   load_balancer_id = hcloud_load_balancer.this.id
#   protocol         = "tcp"
#   listen_port      = 7445
#   destination_port = 7445
#   proxyprotocol    = false
# }
resource "hcloud_load_balancer_service" "apid" {
  load_balancer_id = hcloud_load_balancer.this.id
  protocol         = "tcp"
  listen_port      = 50000
  destination_port = 50000
  proxyprotocol    = false
}
resource "hcloud_load_balancer_service" "trustd" {
  load_balancer_id = hcloud_load_balancer.this.id
  protocol         = "tcp"
  listen_port      = 50001
  destination_port = 50001
  proxyprotocol    = false
}

# load balancer targets
resource "hcloud_load_balancer_target" "this" {
  for_each         = hcloud_server.control_planes
  load_balancer_id = hcloud_load_balancer.this.id
  type             = "server"
  server_id        = each.value.id
  use_private_ip   = true

  depends_on = [
    hcloud_load_balancer_network.machines,
    hcloud_server.control_planes,
  ]
}
