locals {
  cluster_endpoint = "https://${var.endpoint}:6443"

  cidrs6 = {
    # 108 is the largest supported 128b range
    pods     = "fc00::10:0/108"
    services = "fc00::0:0/108"
  }

  cert_sans = [
    var.endpoint,
  ]

  patches_common = flatten([
    yamlencode({
      cluster = {
        network = {
          dnsDomain = "cluster.local"
          cni = {
            name = "none"
            # name = "custom"
            # urls = [
            #   "https://raw.githubusercontent.com/miran248/terraform-talos-modules/95c41f61ca0801479fd713d6c26810b8bdfcbb9d/manifests/cilium.yaml",
            # ]
          }
          podSubnets     = [local.cidrs6.pods]
          serviceSubnets = [local.cidrs6.services]
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
            forwardKubeDNSToHost = false # doesn't work on singlestack ipv6! 169.254.116.108 address is hardcoded!
            resolveMemberNames   = true
          }
        }
        kubelet = {
          clusterDNS = [cidrhost(local.cidrs6.services, 10)]
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
            enabled = false
          }
        }
        sysctls = {
          "net.core.somaxconn"          = 65535
          "net.core.netdev_max_backlog" = 4096

          "net.ipv6.conf.all.forwarding" = 1
          "net.ipv4.ip_forward"          = 1
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
            extraArgs = merge(
              {
                bind-address        = "::"
                cloud-provider      = "external"
                controllers         = "*,tokencleaner,-node-ipam-controller"
                allocate-node-cidrs = false
              },
            )
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
            # manifests = [
            #   "https://raw.githubusercontent.com/miran248/terraform-talos-modules/v1.3.0/manifests/talos-cloud-controller-manager.yaml",
            # ]
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
