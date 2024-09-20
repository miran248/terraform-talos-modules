locals {
  prefix = "${var.cluster.name}-${var.zone}"

  cidrs4 = {
    machines = "192.168.${var.zone}.0/24" # 192.168.1.0/24
  }

  nodes = merge(flatten([
    [for i, node in var.nodes.control_planes : node.removed ? {} : {
      "${cidrhost(local.cidrs4.machines, 11 + i)}" = {
        private_ip4_network_24 = local.cidrs4.machines
        private_ip4_gateway_32 = "${cidrhost(local.cidrs4.machines, 1)}/32"      # 192.168.1.1/32
        private_ip4_gateway_24 = "${cidrhost(local.cidrs4.machines, 1)}/24"      # 192.168.1.1/24
        private_ip4_gateway    = cidrhost(local.cidrs4.machines, 1)              # 192.168.1.1
        private_ip4_32         = "${cidrhost(local.cidrs4.machines, 11 + i)}/32" # 192.168.1.11/32
        private_ip4_24         = "${cidrhost(local.cidrs4.machines, 11 + i)}/24" # 192.168.1.11/24
        private_ip4            = cidrhost(local.cidrs4.machines, 11 + i)         # 192.168.1.11
        name                   = "${local.prefix}-control-plane-${i + 1}"
        server_type            = node.server_type
        talos                  = { machine_type = "controlplane" }
        patches = flatten([
          var.cluster.patches.control_planes,
          var.patches.common,
          var.patches.control_planes,
          node.patches,
        ])
      }
    }],
    [for i, node in var.nodes.workers : node.removed ? {} : {
      "${cidrhost(local.cidrs4.machines, 21 + i)}" = {
        private_ip4_network_24 = local.cidrs4.machines
        private_ip4_gateway_32 = "${cidrhost(local.cidrs4.machines, 1)}/32"      # 192.168.1.1/32
        private_ip4_gateway_24 = "${cidrhost(local.cidrs4.machines, 1)}/24"      # 192.168.1.1/24
        private_ip4_gateway    = cidrhost(local.cidrs4.machines, 1)              # 192.168.1.1
        private_ip4_32         = "${cidrhost(local.cidrs4.machines, 21 + i)}/32" # 192.168.1.21/32
        private_ip4_24         = "${cidrhost(local.cidrs4.machines, 21 + i)}/24" # 192.168.1.21/24
        private_ip4            = cidrhost(local.cidrs4.machines, 21 + i)         # 192.168.1.21
        name                   = "${local.prefix}-worker-${i + 1}"
        server_type            = node.server_type
        talos                  = { machine_type = "worker" }
        patches = flatten([
          var.cluster.patches.workers,
          var.patches.common,
          var.patches.workers,
          node.patches,
        ])
      }
    }],
  ])...)
}
