locals {
  cluster_endpoint = "https://${var.endpoint}:6443"

  pools = {
    control_planes = merge(flatten([for pool in var.pools : pool.control_planes])...)
    workers        = merge(flatten([for pool in var.pools : pool.workers])...)
  }

  cert_sans = flatten([
    var.endpoint,
    keys(local.pools.control_planes),
    keys(local.pools.workers),
  ])

  machine_subnets = [var.layout.cidrs4.machines]
  service_subnets = [var.layout.cidrs4.services]
  pod_subnets     = [var.layout.cidrs4.pods]

  partials = {
    common = {
      debug = var.debug
      cluster = {
        network = {
          dnsDomain      = "cluster.local"
          podSubnets     = local.pod_subnets
          serviceSubnets = local.service_subnets
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
        # install = {
        #   extraKernelArgs = [
        #     "ipv6.disable=1",
        #   ]
        # }
        kubelet = {
          clusterDNS = [var.layout.ips4.cluster_dns]
          extraArgs = {
            cloud-provider             = "external"
            rotate-server-certificates = false
          }
          nodeIP = {
            validSubnets = local.machine_subnets
          }
        }
        # network = {
        #   extraHostEntries = [
        #     {
        #       ip      = "127.0.0.1"
        #       aliases = [var.endpoint]
        #     },
        #   ]
        # }
        sysctls = {
          "net.core.somaxconn"          = 65535
          "net.core.netdev_max_backlog" = 4096
        }
        time = {
          servers = ["/dev/ptp0"]
        }
      }
    }
    control_plane = {
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
            bind-address = "0.0.0.0"
          }
        }
        controllerManager = {
          extraArgs = {
            bind-address             = "0.0.0.0"
            node-cidr-mask-size-ipv4 = 24
            cloud-provider           = "external"
          }
        }
        etcd = {
          advertisedSubnets = local.machine_subnets
          extraArgs = {
            "listen-metrics-urls" = "http://0.0.0.0:2381"
          }
        }
        externalCloudProvider = {
          enabled = true
          manifests = [
            "https://raw.githubusercontent.com/siderolabs/talos-cloud-controller-manager/v1.6.0/docs/deploy/cloud-controller-manager-daemonset.yml",
          ]
        }
        proxy = {
          disabled = true
        }
        scheduler = {
          extraArgs = {
            bind-address = "0.0.0.0"
          }
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
    }
    worker = {

    }
  }

  machine_configurations = {
    control_planes = merge([for ip4, control_plane in local.pools.control_planes : {
      "${ip4}" = yamlencode(yamldecode(data.talos_machine_configuration.control_planes[ip4].machine_configuration))
    }]...)
    workers = merge([for ip4, worker in local.pools.workers : {
      "${ip4}" = yamlencode(yamldecode(data.talos_machine_configuration.workers[ip4].machine_configuration))
    }]...)
  }
  patches = {
    control_planes = merge([for ip4, control_plane in local.pools.control_planes : {
      "${ip4}" = flatten([
        yamlencode(local.partials.common),
        yamlencode(local.partials.control_plane),
        control_plane.patches,
        yamlencode({ machine = { nodeLabels = control_plane.node_labels } }),
      ])
    }]...)
    workers = merge([for ip4, worker in local.pools.workers : {
      "${ip4}" = flatten([
        yamlencode(local.partials.common),
        # yamlencode(local.partials.worker),
        worker.patches,
        yamlencode({ machine = { nodeLabels = worker.node_labels } }),
      ])
    }]...)
  }

  control_planes = merge([for ip4, control_plane in local.pools.control_planes : {
    "${ip4}" = {
      machine_configuration = local.machine_configurations.control_planes[ip4]
      patches               = local.patches.control_planes[ip4]
    }
  }]...)
  workers = merge([for ip4, worker in local.pools.workers : {
    "${ip4}" = {
      machine_configuration = local.machine_configurations.workers[ip4]
      patches               = local.patches.workers[ip4]
    }
  }]...)
}
