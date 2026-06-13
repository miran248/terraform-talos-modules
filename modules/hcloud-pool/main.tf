locals {
  # s1: merge control_planes and workers vars into one keyed map with kind
  s1 = merge(
    { for i, node in var.control_planes :
      "${var.prefix}-control-plane-${i + 1}" => merge(node, { kind = "control-plane" }) if node.removed == false
    },
    { for i, node in var.workers :
      "${var.prefix}-worker-${i + 1}" => merge(node, { kind = "worker" }) if node.removed == false
    },
  )

  # s2: add derived fields (name, patches, ip_64)
  s2 = { for key, node in local.s1 :
    key => merge(node, {
      name    = key
      patches = flatten([var.patches.common, node.kind == "control-plane" ? var.patches.control_planes : var.patches.workers, node.patches])
      ip_64   = hcloud_primary_ip.this[key].ip_network
    })
  }

  ids = {
    group = hcloud_placement_group.this.id
    ips   = { v6 = { for key, ip in hcloud_primary_ip.this : key => ip.id } }
  }

  nodes = local.s2
}

# ips
resource "hcloud_primary_ip" "this" {
  for_each    = local.s1
  name        = each.key
  location    = var.location
  type        = "ipv6"
  auto_delete = false

  delete_protection = false
}

# placement groups
resource "hcloud_placement_group" "this" {
  name = var.prefix
  type = "spread"
}
