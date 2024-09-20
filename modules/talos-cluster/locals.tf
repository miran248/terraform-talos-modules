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
          podSubnets = [
            local.cidrs6.pods,
            local.cidrs4.pods,
          ]
          serviceSubnets = [
            local.cidrs6.services,
            local.cidrs4.services,
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
          clusterDNS = [
            cidrhost(local.cidrs6.services, 10),
            cidrhost(local.cidrs4.services, 10),
          ]
          extraArgs = {
            cloud-provider             = "external"
            rotate-server-certificates = true
          }
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
              advertise-address = "0.0.0.0"
            }
          }
          controllerManager = {
            extraArgs = {
              cloud-provider           = "external"
              node-cidr-mask-size-ipv4 = 24
              node-cidr-mask-size-ipv6 = 120
            }
          }
          externalCloudProvider = {
            enabled = true
            manifests = [
              "https://raw.githubusercontent.com/miran248/terraform-talos-modules/fb8b095d3ef016c920c15d837c447e40f77a4a9a/manifests/talos-cloud-controller-manager.yaml",
            ]
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
