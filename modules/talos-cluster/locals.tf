locals {
  s1 = {
    control_planes = merge([for i, pool in var.pools : pool.control_planes]...)
    workers        = merge([for i, pool in var.pools : pool.workers]...)
  }
  s2 = {
    nodes = merge(local.s1.control_planes, local.s1.workers)

    aliases = {
      control_planes = merge([for key, node in local.s1.control_planes : {
        "${key}" = flatten([node.aliases, "c${index(keys(local.s1.control_planes), key) + 1}"])
      }]...)
      workers = merge([for key, node in local.s1.workers : {
        "${key}" = flatten([node.aliases, "w${index(keys(local.s1.workers), key) + 1}"])
      }]...)
    }
  }
  s3 = {
    aliases = merge(local.s2.aliases.control_planes, local.s2.aliases.workers)
  }
  s4 = {
    cert_sans = flatten([for key, node in local.s2.nodes : [
      var.endpoint,
      node.public_ip6,
      local.s3.aliases[key],
    ]])
  }
  s5 = {
    patches_common = flatten([
      file("${path.module}/patches/common.yaml"),
      yamlencode({
        machine = {
          certSANs = local.s4.cert_sans
        }
      }),
      var.patches.common,
    ])
  }
  s6 = {
    patches = {
      control_planes = flatten([
        local.s5.patches_common,
        file("${path.module}/patches/control-planes.yaml"),
        yamlencode({
          cluster = {
            apiServer = {
              certSANs = local.s4.cert_sans
            }
            etcd = {
              advertisedSubnets = [for key, node in local.s2.nodes : node.public_ip6_64]
            }
          }
        }),
        var.patches.control_planes,
      ])
      workers = flatten([
        local.s5.patches_common,
        var.patches.workers,
      ])
    }
  }
  s7 = {
    control_planes = merge([for key, node in local.s1.control_planes : {
      "${key}" = merge(node, {
        talos = { machine_type = "controlplane" }
        patches = flatten([
          local.s6.patches.control_planes,
          yamlencode({
            machine = {
              network = {
                extraHostEntries = [{
                  ip      = node.public_ip6
                  aliases = local.s3.aliases[key]
                }]
              }
            }
          }),
          node.patches,
        ])
      })
    }]...)
    workers = merge([for key, node in local.s1.workers : {
      "${key}" = merge(node, {
        talos = { machine_type = "worker" }
        patches = flatten([
          local.s6.patches.workers,
          yamlencode({
            machine = {
              network = {
                extraHostEntries = [{
                  ip      = node.public_ip6
                  aliases = local.s3.aliases[key]
                }]
              }
            }
          }),
          node.patches,
        ])
      })
    }]...)
  }

  cluster_endpoint = "https://${var.endpoint}:6443"

  nodes = merge(local.s7.control_planes, local.s7.workers)

  names = {
    control_planes = [for key, node in local.s1.control_planes : node.name]
    workers        = [for key, node in local.s1.workers : node.name]
  }
  public_ips6 = {
    control_planes = [for key, node in local.s1.control_planes : node.public_ip6]
    workers        = [for key, node in local.s1.workers : node.public_ip6]
  }

  configs = merge([for key, config in data.talos_machine_configuration.this : {
    "${key}" = yamlencode(yamldecode(config.machine_configuration))
  }]...)
}
