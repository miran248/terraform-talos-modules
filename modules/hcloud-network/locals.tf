locals {
  ids = {
    network  = hcloud_network.this.id
    machines = hcloud_network_subnet.machines.id
    ips6     = merge([for key, ip in hcloud_primary_ip.ips6 : { "${key}" = ip.id }]...)
    ips4     = merge([for key, ip in hcloud_primary_ip.ips4 : { "${key}" = ip.id }]...)
  }

  pool_nodes1 = merge([for key, node in var.pool.nodes : {
    "${key}" = merge(
      node,
      var.cluster.features.ip6 ? {
        public_ip6_network_128 = cidrsubnet(hcloud_primary_ip.ips6[key].ip_network, 64, 0)    # 2000:2:3:4::/128
        public_ip6_network_64  = hcloud_primary_ip.ips6[key].ip_network                       # 2000:2:3:4::/64
        public_ip6_128         = "${cidrhost(hcloud_primary_ip.ips6[key].ip_network, 1)}/128" # 2000:2:3:4::1/128
        public_ip6_64          = "${cidrhost(hcloud_primary_ip.ips6[key].ip_network, 1)}/64"  # 2000:2:3:4::1/64
        public_ip6             = cidrhost(hcloud_primary_ip.ips6[key].ip_network, 1)          # 2000:2:3:4::1
        } : {
        public_ip6_network_128 = null
        public_ip6_network_64  = null
        public_ip6_128         = null
        public_ip6_64          = null
        public_ip6             = null
      },
      var.cluster.features.ip4 ? {
        public_ip4_32 = "${hcloud_primary_ip.ips4[key].ip_address}/32" # 1.2.3.4/32
        public_ip4    = hcloud_primary_ip.ips4[key].ip_address         # 1.2.3.4
        } : {
        public_ip4_32 = null
        public_ip4    = null
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
                nameservers = flatten([
                  var.cluster.features.ip6 == false ? [] : [
                    "2a01:4ff:ff00::add:2", # hetzner
                    "2a01:4ff:ff00::add:1", # hetzner
                  ],
                  var.cluster.features.ip4 == false ? [] : [
                    "185.12.64.2", # hetzner
                    "185.12.64.1", # hetzner
                  ],
                ])
              }
            }
          }),
        ])
      }
    )
  }]...)
}
