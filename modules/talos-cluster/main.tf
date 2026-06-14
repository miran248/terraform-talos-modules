locals {
  pool_nodes = merge([for pool in var.pools : pool.nodes]...)

  ordinals = merge(
    { for i, key in [for k, v in local.pool_nodes : k if v.kind == "control-plane"] : key => "c${i + 1}" },
    { for i, key in [for k, v in local.pool_nodes : k if v.kind == "worker"] : key => "w${i + 1}" },
  )

  aliases = { for key, node in local.pool_nodes : key => flatten([node.aliases, local.ordinals[key]]) }

  cert_sans = flatten([
    var.endpoint,
    [for key, _ in local.pool_nodes : local.aliases[key]],
  ])

  mode = length(var.pools) > 0 ? var.pools[0].mode : "ipv6"

  patches = {
    common = flatten([
      file("${path.module}/patches/common-${local.mode}.yaml"),
      yamlencode({ machine = { certSANs = local.cert_sans } }),
      var.patches.common,
    ])
    control_planes = flatten([
      file("${path.module}/patches/control-planes-${local.mode}.yaml"),
      yamlencode({
        cluster = {
          apiServer = { certSANs = local.cert_sans }
          etcd      = { advertisedSubnets = [for _, node in local.pool_nodes : node.ip_cidr] }
        }
      }),
      var.patches.control_planes,
    ])
    workers = var.patches.workers
  }

  nodes = { for key, node in local.pool_nodes :
    key => merge(node, {
      talos   = { machine_type = node.kind == "control-plane" ? "controlplane" : "worker" }
      aliases = local.aliases[key]
      patches = flatten([
        local.patches.common,
        node.kind == "control-plane" ? local.patches.control_planes : local.patches.workers,
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
  configs          = { for key, config in data.talos_machine_configuration.this : key => config.machine_configuration }
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_machine_configuration" "this" {
  for_each           = local.nodes
  cluster_endpoint   = local.cluster_endpoint
  cluster_name       = var.name
  config_patches     = each.value.patches
  kubernetes_version = var.kubernetes_version
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  machine_type       = each.value.talos.machine_type
  talos_version      = var.talos_version
}

data "talos_client_configuration" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  cluster_name         = var.name
  endpoints            = [local.endpoint]
}
