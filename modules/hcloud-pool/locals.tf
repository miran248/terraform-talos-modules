locals {
  s1 = {
    control_planes = { for i, node in var.control_planes :
      "${var.prefix}-control-plane-${i + 1}" => merge(node, {
        name = "${var.prefix}-control-plane-${i + 1}"
        patches = flatten([
          var.patches.common,
          var.patches.control_planes,
          <<-EOF
            apiVersion: v1alpha1
            kind: HostnameConfig
            hostname: ${var.prefix}-control-plane-${i + 1}
            auto: off
          EOF
          ,
          node.patches,
        ])
      }) if node.removed == false
    }
    workers = { for i, node in var.workers :
      "${var.prefix}-worker-${i + 1}" => merge(node, {
        name = "${var.prefix}-worker-${i + 1}"
        patches = flatten([
          var.patches.common,
          var.patches.workers,
          <<-EOF
            apiVersion: v1alpha1
            kind: HostnameConfig
            hostname: ${var.prefix}-worker-${i + 1}
            auto: off
          EOF
          ,
          node.patches,
        ])
      }) if node.removed == false
    }
  }
  s2 = {
    nodes = merge(local.s1.control_planes, local.s1.workers)
  }
  s3 = {
    ips6 = { for key, ip in hcloud_primary_ip.ips6 :
      key => {
        public_ip6_id         = ip.id
        public_ip6_network_64 = ip.ip_network                      # 2000:2:3:4::/64
        public_ip6            = cidrhost(ip.ip_network, 1)         # 2000:2:3:4::1
      }
    }
  }

  ids = {
    group = hcloud_placement_group.this.id
  }

  control_planes = { for key, node in local.s1.control_planes :
    key => merge(node, local.s3.ips6[key])
  }
  workers = { for key, node in local.s1.workers :
    key => merge(node, local.s3.ips6[key])
  }
  nodes = merge(local.control_planes, local.workers)
}
