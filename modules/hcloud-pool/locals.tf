locals {
  s1 = {
    control_planes = merge([for i, node in var.control_planes : node.removed ? {} : {
      "${join("-", [var.prefix, "control-plane", i + 1])}" = merge(node, {
        name = join("-", [var.prefix, "control-plane", i + 1])
        patches = flatten([
          var.patches.common,
          var.patches.control_planes,
          node.patches,
        ])
      })
    }]...)
    workers = merge([for i, node in var.workers : node.removed ? {} : {
      "${join("-", [var.prefix, "worker", i + 1])}" = merge(node, {
        name = join("-", [var.prefix, "worker", i + 1])
        patches = flatten([
          var.patches.common,
          var.patches.workers,
          node.patches,
        ])
      })
    }]...)
  }
  s2 = {
    nodes = merge(local.s1.control_planes, local.s1.workers)
  }
  s3 = {
    ips6 = merge([for key, ip in hcloud_primary_ip.ips6 : {
      "${key}" = {
        public_ip6_id         = ip.id
        public_ip6_network_64 = ip.ip_network                      # 2000:2:3:4::/64
        public_ip6_64         = "${cidrhost(ip.ip_network, 1)}/64" # 2000:2:3:4::1/64
        public_ip6            = cidrhost(ip.ip_network, 1)         # 2000:2:3:4::1
      }
    }]...)
  }

  control_planes = merge([for key, node in local.s1.control_planes : {
    "${key}" = merge(node, local.s3.ips6[key])
  }]...)
  workers = merge([for key, node in local.s1.workers : {
    "${key}" = merge(node, local.s3.ips6[key])
  }]...)
  nodes = merge(local.control_planes, local.workers)
}
