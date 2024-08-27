locals {
  prefix = "${var.prefix}-${var.zone.zone}"

  names = {
    router        = "${local.prefix}-router"
    router_client = "${local.prefix}-router-client"
  }

  control_planes = merge([for i, node in var.nodes.control_planes : node.removed ? {} : {
    "${var.zone.ips4.control_planes[i]}" = {
      name        = "${local.prefix}-control-plane-${i + 1}"
      server_type = node.server_type
      patches     = concat(var.patches.control_planes, node.patches)
      node_labels = merge(var.node_labels.control_planes, node.node_labels)
    }
  }]...)
  workers = merge([for i, node in var.nodes.workers : node.removed ? {} : {
    "${var.zone.ips4.workers[i]}" = {
      name        = "${local.prefix}-worker-${i + 1}"
      server_type = node.server_type
      patches     = concat(var.patches.workers, node.patches)
      node_labels = merge(var.node_labels.workers, node.node_labels)
    }
  }]...)
}
