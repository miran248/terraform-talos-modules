locals {
  ids = {
    ips6 = merge([for key, ip in hcloud_primary_ip.ips6 : { "${key}" = ip.id }]...)
  }

  pool_nodes1 = merge([for key, node in var.pool.nodes : {
    "${key}" = merge(
      node,
      {
        public_ip6_network_64 = hcloud_primary_ip.ips6[key].ip_network                      # 2000:2:3:4::/64
        public_ip6_64         = "${cidrhost(hcloud_primary_ip.ips6[key].ip_network, 1)}/64" # 2000:2:3:4::1/64
        public_ip6            = cidrhost(hcloud_primary_ip.ips6[key].ip_network, 1)         # 2000:2:3:4::1
      }
    )
  }]...)

  nodes = merge([for key, node in local.pool_nodes1 : {
    "${key}" = merge(
      node,
      {
        patches = flatten([
          node.patches,
          yamlencode({
            machine = {
              network = {
                kubespan = {
                  mtu = 1370 # Hcloud has a MTU of 1450 (KubeSpanMTU = UnderlyingMTU - 80)
                }
                nameservers = [
                  "2a01:4ff:ff00::add:2", # hetzner
                  "2a01:4ff:ff00::add:1", # hetzner
                ]
              }
            }
          }),
        ])
      }
    )
  }]...)
}
