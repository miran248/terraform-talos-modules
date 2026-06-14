locals {
  patches = {
    common = [
      <<-EOF
        machine:
          install:
            disk: /dev/vdb
            wipe: true
          nodeLabels:
            provider: scaleway
            topology.kubernetes.io/zone: ${var.zone}
            topology.kubernetes.io/region: ${replace(var.zone, "/-[0-9]+$/", "")}
      EOF
      ,
      <<-EOF
        apiVersion: v1alpha1
        kind: VolumeConfig
        name: EPHEMERAL
        provisioning:
          diskSelector:
            match: disk.dev_path == "/dev/vdb"
          maxSize: 40GiB
          minSize: 2GiB
      EOF
      ,
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
      ip_cidr = scaleway_instance_ip.this[key].prefix
    })
  }

  ids = {
    group = scaleway_instance_placement_group.this.id
    ips   = { for key, ip in scaleway_instance_ip.this : key => ip.id }
  }
}

# ips
resource "scaleway_instance_ip" "this" {
  for_each = local.keyed_nodes
  zone     = var.zone
  type     = var.mode == "ipv6" ? "routed_ipv6" : "routed_ipv4"
}

# placement groups
resource "scaleway_instance_placement_group" "this" {
  name        = var.prefix
  policy_type = "max_availability"
  # policy_mode = "enforced"
  policy_mode = "optional"
  zone        = var.zone
}
