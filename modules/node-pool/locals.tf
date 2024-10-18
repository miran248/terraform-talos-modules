locals {
  prefix = "${var.cluster.name}-${var.zone}"

  cidrs4 = {
    machines = "192.168.${var.zone}.0/24" # 192.168.1.0/24
  }

  nodes = merge(flatten([
    [for i, node in var.nodes.control_planes : node.removed ? {} : {
      "${cidrhost(local.cidrs4.machines, 11 + i)}" = {
        name        = "${local.prefix}-control-plane-${i + 1}"
        server_type = node.server_type
        talos       = { machine_type = "controlplane" }
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
        name        = "${local.prefix}-worker-${i + 1}"
        server_type = node.server_type
        talos       = { machine_type = "worker" }
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
