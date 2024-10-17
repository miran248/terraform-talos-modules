locals {
  network_nodes1 = merge([for key, network in var.networks : network.nodes]...)

  cert_sans = flatten([
    [for key, node in local.network_nodes1 : node.public_ip6],
    [for key, node in local.network_nodes1 : node.public_ip4],
  ])

  patches_common = [
    # yamlencode({
    #   cluster = {
    #     network = {
    #       # podSubnets = [for key, node in local.network_nodes1 : cidrsubnet(node.public_ip6_network_64, 44, 1)]
    #       podSubnets = [cidrsubnet(node.public_ip6_network_64, 44, 1)]
    #       # serviceSubnets = [cidrsubnet(node.public_ip6_network_64, 44, 2)]
    #     }
    #   }
    #   # machine = {
    #   #   kubelet = {
    #   #     clusterDNS = [cidrhost(cidrsubnet(node.public_ip6_network_64, 44, 2), 10)]
    #   #   }
    #   # }
    # }),
    yamlencode({
      cluster = {
        inlineManifests = [for key, node in local.network_nodes1 : {
          name     = "talos-cilium-node-${key}"
          contents = <<-EOF
            apiVersion: cilium.io/v2
            kind: CiliumNodeConfig
            metadata:
              name: "talos-cilium-node-${key}"
              namespace: kube-system
            spec:
              nodeSelector:
                matchLabels:
                  "kubernetes.io/hostname": "${node.name}"
              defaults:
                ipv6-node: "${node.public_ip6}"
                ipv6-native-routing-cidr: "${node.public_ip6_network_64}"
                ipv6-service-range: "${cidrsubnet(node.public_ip6_network_64, 16, 1)}"
                ipv6-range: "${cidrsubnet(node.public_ip6_network_64, 16, 2)}"
          EOF
        }]
      }
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
          # advertisedSubnets = distinct([for key, node in local.network_nodes1 : node.private_ip4_network_24])
          advertisedSubnets = compact(flatten(
            [for key, node in local.network_nodes1 : node.talos.machine_type == "controlplane"
              ? [node.public_ip6_128, node.public_ip4_32]
              : []
            ],
          ))
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
          # yamlencode({
          #   cluster = {
          #     network = {
          #       # podSubnets = [for key, node in local.network_nodes1 : cidrsubnet(node.public_ip6_network_64, 44, 1)]
          #       podSubnets = [cidrsubnet(node.public_ip6_network_64, 44, 1)]
          #       # serviceSubnets = [cidrsubnet(node.public_ip6_network_64, 44, 2)]
          #     }
          #   }
          #   # machine = {
          #   #   kubelet = {
          #   #     clusterDNS = [cidrhost(cidrsubnet(node.public_ip6_network_64, 44, 2), 10)]
          #   #   }
          #   # }
          # }),
          yamlencode({
            machine = {
              nodeAnnotations = {
                "network.cilium.io/ipv6-cilium-host" = node.public_ip6
                "network.cilium.io/ipv6-health-ip"   = cidrhost(node.public_ip6_network_64, 2)
                "network.cilium.io/ipv6-Ingress-ip"  = cidrhost(node.public_ip6_network_64, 3)
                "network.cilium.io/ipv6-pod-cidr"    = node.public_ip6_network_64
              }
              # kubelet = {
              #   # extraArgs = {
              #   #   # prefers ipv6 when possible
              #   #   node-ip = join(",", compact([
              #   #     node.public_ip6,
              #   #     node.public_ip4,
              #   #     node.private_ip4,
              #   #   ]))
              #   # }
              #   nodeIP = {
              #     # all ips are marked as InternalIP by talos-ccm
              #     # public ips must be included, otherwise it always uses ipv4 cidrs!
              #     # TODO: public ips should be ExternalIP!
              #     validSubnets = compact([
              #       # node.public_ip6_network_64,
              #       # node.public_ip4_32,
              #       node.private_ip4_network_24,
              #     ])
              #   }
              # }
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
