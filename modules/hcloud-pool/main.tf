# data centers
data "hcloud_datacenter" "this" {
  name = var.datacenter
}
data "hcloud_location" "this" {
  name = data.hcloud_datacenter.this.location.name
}

# ips
resource "hcloud_primary_ip" "ips6" {
  for_each      = local.s3.nodes
  name          = "${each.value.name}-ip6"
  datacenter    = data.hcloud_datacenter.this.name
  type          = "ipv6"
  assignee_type = "server"
  auto_delete   = false

  delete_protection = false
}

# networks
resource "hcloud_network" "this" {
  count    = var.cidr == null ? 0 : 1
  name     = var.prefix
  ip_range = var.cidr

  delete_protection = false
}
resource "hcloud_network_subnet" "this" {
  count        = var.cidr == null ? 0 : 1
  network_zone = data.hcloud_location.this.network_zone
  network_id   = hcloud_network.this[0].id
  ip_range     = hcloud_network.this[0].ip_range
  type         = "cloud"
}

# load balancers
resource "hcloud_load_balancer" "this" {
  count              = var.load_balancer_ip == null ? 0 : 1
  location           = data.hcloud_location.this.name
  name               = var.prefix
  load_balancer_type = "lb11"

  delete_protection = false

  algorithm {
    type = "round_robin"
  }
}
resource "hcloud_load_balancer_network" "this" {
  count            = var.load_balancer_ip == null ? 0 : 1
  subnet_id        = hcloud_network_subnet.this[0].id
  load_balancer_id = hcloud_load_balancer.this[0].id
  ip               = var.load_balancer_ip

  enable_public_interface = true
}
