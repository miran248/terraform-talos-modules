locals {
  network_nodes1 = merge([for key, network in var.networks : network.nodes]...)

  cert_sans = flatten([for key, node in local.network_nodes1 : [
    node.public_ip6,
    "n${index(keys(local.network_nodes1), key) + 1}"
  ]])

  extra_hosts = [for key, node in local.network_nodes1 : {
    ip = node.public_ip6
    aliases = [
      "n${index(keys(local.network_nodes1), key) + 1}",
    ]
  }]

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
          advertisedSubnets = [for key, node in local.network_nodes1 : node.public_ip6_64]
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
              network = {
                extraHostEntries = local.extra_hosts
              }
            }
          }),
        ])
      },
    )
  }]...)

  names = {
    control_planes = flatten([for key, node in local.network_nodes1 : node.talos.machine_type == "controlplane" ? [node.name] : []])
    workers        = flatten([for key, node in local.network_nodes1 : node.talos.machine_type == "worker" ? [node.name] : []])
  }
  public_ips6 = {
    control_planes = flatten([for key, node in local.network_nodes1 : node.talos.machine_type == "controlplane" ? [node.public_ip6] : []])
    workers        = flatten([for key, node in local.network_nodes1 : node.talos.machine_type == "worker" ? [node.public_ip6] : []])
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
