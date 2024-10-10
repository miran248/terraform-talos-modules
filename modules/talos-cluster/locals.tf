locals {
  cluster_endpoint = "https://${var.endpoint}:6443"

  cidrs6 = {
    # 108 is the largest supported 128b range
    pods     = "fc00::10:0/108"
    services = "fc00::0:0/108"
  }

  cidrs4 = {
    # 12 is the largest supported 32b range
    pods     = "10.16.0.0/12"
    services = "10.0.0.0/12"
  }

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
          cni = {
            name = "custom"
            urls = (var.features.ip6
              # sets ipv6.enabled: true
              ? ["https://raw.githubusercontent.com/miran248/terraform-talos-modules/v1.3.0/manifests/cilium-ip6.yaml"]
              # sets ipv6.enabled: false
              : ["https://raw.githubusercontent.com/miran248/terraform-talos-modules/v1.3.0/manifests/cilium-ip4.yaml"]
            )
          }
          # order matters!
          podSubnets = (var.features.ip6
            ? [
              local.cidrs6.pods,
              local.cidrs4.pods,
            ]
            : [
              local.cidrs4.pods,
              local.cidrs6.pods,
          ])
          serviceSubnets = (var.features.ip6
            ? [
              local.cidrs6.services,
              local.cidrs4.services,
            ]
            : [
              local.cidrs4.services,
              local.cidrs6.services,
          ])
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
          clusterDNS = (var.features.ip6
            ? [
              cidrhost(local.cidrs6.services, 10),
              cidrhost(local.cidrs4.services, 10),
            ]
            : [
              cidrhost(local.cidrs4.services, 10),
              cidrhost(local.cidrs6.services, 10),
          ])
          # https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/
          extraArgs = {
            cloud-provider             = "external"
            rotate-server-certificates = true
          }
          extraConfig = {
            address            = "::"
            healthzBindAddress = "::"
          }
        }
        network = {
          kubespan = {
            enabled                     = true
            advertiseKubernetesNetworks = false
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
            # https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/
            extraArgs = {
              advertise-address = "::"
              bind-address      = "::"
            }
          }
          controllerManager = {
            # https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/
            extraArgs = {
              bind-address             = "::"
              cloud-provider           = "external"
              node-cidr-mask-size-ipv6 = 120
              node-cidr-mask-size-ipv4 = 24
            }
          }
          etcd = {
            # https://etcd.io/docs/v3.5/op-guide/configuration/
            extraArgs = {
              listen-metrics-urls = "http://[::]:2381"
            }
          }
          scheduler = {
            # https://kubernetes.io/docs/reference/command-line-tools-reference/kube-scheduler/
            extraArgs = {
              bind-address = "::"
            }
          }
          externalCloudProvider = {
            enabled = true
            manifests = (var.features.ip6
              # sets preferIPv6: true to prevent ccm from picking hetzner's cgnat ip address..
              ? ["https://raw.githubusercontent.com/miran248/terraform-talos-modules/v1.3.0/manifests/talos-cloud-controller-manager.yaml"]
              # sets preferIPv6: false to prevent ccm from picking machine's link-local ip address..
              : ["https://raw.githubusercontent.com/siderolabs/talos-cloud-controller-manager/v1.8.0/docs/deploy/cloud-controller-manager-daemonset.yml"]
            )
          }
        }
        machine = {
          features = {
            kubernetesTalosAPIAccess = {
              enabled = true
              allowedRoles = [
                "os:reader",
              ]
              allowedKubernetesNamespaces = [
                "kube-system",
              ]
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
