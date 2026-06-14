locals {
  patches = {
    common = [
      <<-EOF
        machine:
          nodeLabels:
            provider: hcloud
            topology.kubernetes.io/zone: ${var.location}
            topology.kubernetes.io/region: ${var.location}
      EOF
    ]
  }

  keyed_nodes = merge(
    { for i, node in var.control_planes :
      "${var.prefix}-control-plane-${i + 1}" => merge(node, { kind = "control-plane" }) if node.removed == false
    },
    { for i, node in var.workers :
      "${var.prefix}-worker-${i + 1}" => merge(node, { kind = "worker" }) if node.removed == false
    },
  )

  nodes = { for key, node in local.keyed_nodes :
    key => merge(node, {
      name    = key
      patches = flatten([local.patches.common, var.patches.common, node.kind == "control-plane" ? var.patches.control_planes : var.patches.workers, node.patches])
      ip_cidr = var.mode == "ipv6" ? hcloud_primary_ip.this[key].ip_network : "${hcloud_primary_ip.this[key].ip_address}/32"
    })
  }

  ids = {
    group = hcloud_placement_group.this.id
    ips   = { for key, ip in hcloud_primary_ip.this : key => ip.id }
  }
}

# ips
resource "hcloud_primary_ip" "this" {
  for_each    = local.keyed_nodes
  name        = each.key
  location    = var.location
  type        = var.mode
  auto_delete = false

  delete_protection = false
}

# placement groups
resource "hcloud_placement_group" "this" {
  name = var.prefix
  type = "spread"
}
