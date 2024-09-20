locals {
  network_nodes1 = merge([for key, network in var.networks : network.nodes]...)

  cert_sans = flatten([
    [for key, node in local.network_nodes1 : node.public_ip6],
    [for key, node in local.network_nodes1 : node.public_ip4],
  ])

  patches_common = [
    yamlencode({
      machine = {
        certSANs = local.cert_sans
      }
    }),
  ]
  patches_control_planes = [
    yamlencode({
      cluster = {
        apiServer = {
          certSANs = local.cert_sans
        }
        etcd = {
          advertisedSubnets = distinct([for key, node in local.network_nodes1 : node.private_ip4_network_24])
        }
      }
    }),
  ]
  patches_workers = []

  network_nodes2 = merge([for key, node in local.network_nodes1 : {
    "${key}" = merge(
      node,
      {
        patches = flatten([
          node.patches,
          local.patches_common,
          node.talos.machine_type == "controlplane" ? local.patches_control_planes : [],
          node.talos.machine_type == "worker" ? local.patches_workers : [],
          yamlencode({
            machine = {
              kubelet = {
                nodeIP = {
                  validSubnets = [
                    node.private_ip4_network_24,
                  ]
                }
              }
            }
          }),
        ])
      },
    )
  }]...)

  private_ips4 = {
    control_planes = flatten([for key, node in local.network_nodes1 : node.talos.machine_type == "controlplane" ? [node.private_ip4] : []])
    workers        = flatten([for key, node in local.network_nodes1 : node.talos.machine_type == "worker" ? [node.private_ip4] : []])
  }
  public_ips6 = {
    control_planes = flatten([for key, node in local.network_nodes1 : node.talos.machine_type == "controlplane" ? [node.public_ip6] : []])
    workers        = flatten([for key, node in local.network_nodes1 : node.talos.machine_type == "worker" ? [node.public_ip6] : []])
  }
  public_ips4 = {
    control_planes = flatten([for key, node in local.network_nodes1 : node.talos.machine_type == "controlplane" ? [node.public_ip4] : []])
    workers        = flatten([for key, node in local.network_nodes1 : node.talos.machine_type == "worker" ? [node.public_ip4] : []])
  }
  nodes = merge([for key, node in local.network_nodes2 : {
    "${key}" = merge(
      node,
      {
        data = yamlencode(yamldecode(data.talos_machine_configuration.this[key].machine_configuration))
      },
    )
  }]...)
}
