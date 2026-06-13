locals {
  # s1: merge all pool nodes into one map
  s1 = merge([for pool in var.pools : pool.nodes]...)

  # s2: short per-kind ordinal alias (c1/c2... w1/w2...)
  s2 = merge(
    { for i, key in [for k, v in local.s1 : k if v.kind == "control-plane"] : key => "c${i + 1}" },
    { for i, key in [for k, v in local.s1 : k if v.kind == "worker"] : key => "w${i + 1}" },
  )

  # s3: expanded aliases (ordinal + original)
  s3 = { for key, node in local.s1 : key => flatten([node.aliases, local.s2[key]]) }

  # s4: cert SANs
  s4 = flatten([
    var.endpoint,
    [for key, _ in local.s1 : local.s3[key]],
  ])

  # s5: common patches (base for all nodes)
  s5 = flatten([
    file("${path.module}/patches/common.yaml"),
    # yamlencode({ machine = { certSANs = local.s4, install = { image = "ghcr.io/siderolabs/installer:${var.talos_version}" } } }),
    yamlencode({ machine = { certSANs = local.s4 } }),
    var.patches.common,
  ])

  # s6: per-kind full patches
  s6 = {
    control_planes = flatten([
      local.s5,
      file("${path.module}/patches/control-planes.yaml"),
      yamlencode({
        cluster = {
          apiServer = { certSANs = local.s4 }
          etcd      = { advertisedSubnets = [for _, node in local.s1 : node.ip_64] }
        }
      }),
      var.patches.control_planes,
    ])
    workers = flatten([local.s5, var.patches.workers])
  }

  # s7: final nodes map with all derived fields merged in
  s7 = { for key, node in local.s1 :
    key => merge(node, {
      talos   = { machine_type = node.kind == "control-plane" ? "controlplane" : "worker" }
      aliases = local.s3[key]
      patches = flatten([
        node.kind == "control-plane" ? local.s6.control_planes : local.s6.workers,
        <<-EOF
          apiVersion: v1alpha1
          kind: HostnameConfig
          hostname: ${key}
          auto: "off"
        EOF
        ,
        node.patches,
      ])
    })
  }

  endpoint         = var.endpoint
  cluster_endpoint = strcontains(var.endpoint, ":") ? "https://[${var.endpoint}]:6443" : "https://${var.endpoint}:6443"
  nodes            = local.s7
  configs          = { for key, config in data.talos_machine_configuration.this : key => config.machine_configuration }
}
