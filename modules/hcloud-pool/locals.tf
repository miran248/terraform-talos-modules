locals {
  s1 = {
    patches_common = var.cidr == null ? [] : [
      yamlencode({
        machine = {
          kubelet = {
            nodeIP = {
              validSubnets = [
                var.cidr,
              ]
            }
          }
          network = {
            kubespan = {
              filters = {
                endpoints = [
                  "!100.64.0.0/10",
                ]
              }
            }
          }
        }
      }),
    ]
    patches_control_planes = [
      yamlencode({
        cluster = {
          etcd = {
            advertisedSubnets = [
              "!100.64.0.0/10",
            ]
          }
        }
      })
    ]
  }
  s2 = {
    control_planes = merge([for i, node in var.control_planes : node.removed ? {} : {
      "${join("-", [var.prefix, "control-plane", i + 1])}" = merge(node, {
        name        = join("-", [var.prefix, "control-plane", i + 1])
        private_ip4 = var.cidr == null ? null : cidrhost(var.cidr, i + 11)
        patches = flatten([
          local.s1.patches_common,
          local.s1.patches_control_planes,
          var.patches.common,
          var.patches.control_planes,
          node.patches,
        ])
      })
    }]...)
    workers = merge([for i, node in var.workers : node.removed ? {} : {
      "${join("-", [var.prefix, "worker", i + 1])}" = merge(node, {
        name        = join("-", [var.prefix, "worker", i + 1])
        private_ip4 = var.cidr == null ? null : cidrhost(var.cidr, i + 21)
        patches = flatten([
          local.s1.patches_common,
          var.patches.common,
          var.patches.workers,
          node.patches,
        ])
      })
    }]...)
  }
  s3 = {
    nodes = merge(local.s2.control_planes, local.s2.workers)
  }
  s4 = {
    ips6 = { for key, ip in hcloud_primary_ip.ips6 :
      key => {
        public_ip6_id         = ip.id
        public_ip6_network_64 = ip.ip_network                      # 2000:2:3:4::/64
        public_ip6_64         = "${cidrhost(ip.ip_network, 1)}/64" # 2000:2:3:4::1/64
        public_ip6            = cidrhost(ip.ip_network, 1)         # 2000:2:3:4::1
      }
    }
  }

  ids = {
    network       = one(hcloud_network.this[*].id)
    subnet        = one(hcloud_network_subnet.this[*].id)
    load_balancer = one(hcloud_load_balancer.this[*].id)
  }

  control_planes = { for key, node in local.s2.control_planes :
    key => merge(node, local.s4.ips6[key])
  }
  workers = { for key, node in local.s2.workers :
    key => merge(node, local.s4.ips6[key])
  }
  nodes = merge(local.control_planes, local.workers)
}
