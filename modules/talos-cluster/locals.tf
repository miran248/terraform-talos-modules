locals {
  cluster_endpoint = "https://${var.endpoint}:6443"

  cidrs6 = {
    # 108 is the largest supported 128b range
    pods     = "fc00::10:0/108"
    services = "fc00::0:0/108"
  }

  # cidrs4 = {
  #   # 12 is the largest supported 32b range
  #   pods     = "10.16.0.0/12"
  #   services = "10.0.0.0/12"
  # }

  cert_sans = [
    var.endpoint,
    "::1",
    "127.0.0.1",
  ]

  patches_common = flatten([
    yamlencode({
      cluster = {
        network = {
          dnsDomain = "cluster.local"
          # order matters!
          # podSubnets = (var.features.ip6
          #   ? [
          #     local.cidrs6.pods,
          #     local.cidrs4.pods,
          #   ]
          #   : [
          #     local.cidrs4.pods,
          #     local.cidrs6.pods,
          # ])
          # serviceSubnets = (var.features.ip6
          #   ? [
          #     local.cidrs6.services,
          #     local.cidrs4.services,
          #   ]
          #   : [
          #     local.cidrs4.services,
          #     local.cidrs6.services,
          # ])
          podSubnets = [
            local.cidrs6.pods,
          ]
          serviceSubnets = [
            local.cidrs6.services,
          ]
        }
      }
      machine = {
        certSANs = local.cert_sans
        features = {
          rbac                 = true
          stableHostname       = true
          apidCheckExtKeyUsage = true
          diskQuotaSupport     = true
          kubePrism = {
            enabled = true
          }
          hostDNS = {
            enabled              = true
            forwardKubeDNSToHost = true
            resolveMemberNames   = true
          }
        }
        kubelet = {
          # order matters!
          # clusterDNS = (var.features.ip6
          #   ? [
          #     cidrhost(local.cidrs6.services, 10),
          #     cidrhost(local.cidrs4.services, 10),
          #   ]
          #   : [
          #     cidrhost(local.cidrs4.services, 10),
          #     cidrhost(local.cidrs6.services, 10),
          # ])
          clusterDNS = [
            cidrhost(local.cidrs6.services, 10),
          ]
        }
        network = {
          kubespan = {
            enabled                     = true
            advertiseKubernetesNetworks = false
            allowDownPeerBypass         = true
            # harvestExtraEndpoints       = true
          }
        }
        sysctls = {
          "net.core.somaxconn"          = 65535
          "net.core.netdev_max_backlog" = 4096
        }
      }
    }),
    var.patches.common,
  ])

  patches = {
    control_planes = flatten([
      local.patches_common,
      yamlencode({
        cluster = {
          proxy = {
            disabled = true
          }
          discovery = {
            enabled = true
            registries = {
              kubernetes = { disabled = true }
              service    = {}
            }
          }
          apiServer = {
            certSANs = local.cert_sans
            extraArgs = {
              # forces apiserver to use external ip family
              advertise-address = "0.0.0.0"
            }
          }
          controllerManager = {
            extraArgs = {
              # cloud-provider           = "external"
              node-cidr-mask-size-ipv6 = 120
              # node-cidr-mask-size-ipv4 = 24
            }
          }
        }
      }),
      var.patches.control_planes,
    ])
    workers = flatten([
      local.patches_common,
      var.patches.workers,
    ])
  }
}
