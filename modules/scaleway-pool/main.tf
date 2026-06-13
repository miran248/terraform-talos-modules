locals {
  # s1: base patches applied to every node in this pool
  s1 = [
    <<-EOF
      machine:
        install:
          disk: /dev/vdb
          wipe: true
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

  # s2: merge control_planes and workers vars into one keyed map with kind
  s2 = merge(
    { for i, node in var.control_planes :
      "${var.prefix}-control-plane-${i + 1}" => merge(node, { kind = "control-plane" }) if node.removed == false
    },
    { for i, node in var.workers :
      "${var.prefix}-worker-${i + 1}" => merge(node, { kind = "worker" }) if node.removed == false
    },
  )

  # s3: add derived fields (name, patches, ip_64)
  s3 = { for key, node in local.s2 :
    key => merge(node, {
      name    = key
      patches = flatten([local.s1, var.patches.common, node.kind == "control-plane" ? var.patches.control_planes : var.patches.workers, node.patches])
      ip_64   = scaleway_instance_ip.this[key].prefix
    })
  }

  ids = {
    group = scaleway_instance_placement_group.this.id
    ips = {
      v6 = { for key, ip in scaleway_instance_ip.this : key => ip.id }
    }
  }

  nodes = local.s3
}

# ips
resource "scaleway_instance_ip" "this" {
  for_each = local.s2
  zone     = var.zone
  type     = "routed_ipv6"
}

# placement groups
resource "scaleway_instance_placement_group" "this" {
  name        = var.prefix
  policy_type = "max_availability"
  # policy_mode = "enforced"
  policy_mode = "optional"
  zone        = var.zone
}
