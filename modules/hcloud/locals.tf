locals {
  ids = {
    network        = hcloud_network.this.id
    machines       = hcloud_network_subnet.machines.id
    services       = hcloud_network_subnet.services.id
    pods           = hcloud_network_subnet.pods.id
    control_planes = merge([for ip4, machine in hcloud_server.control_planes : { "${ip4}" = machine.id }]...)
    workers        = merge([for ip4, machine in hcloud_server.workers : { "${ip4}" = machine.id }]...)
  }
  ips4 = merge(
    { load_balancer = hcloud_load_balancer.this.ipv4 },
    var.router == null ? {} : { router = hcloud_primary_ip.router_ipv4[0].ip_address }
  )
}
