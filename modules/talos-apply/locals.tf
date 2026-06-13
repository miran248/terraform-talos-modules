locals {
  s1              = merge([for a in var.applies : a.ips.v6]...)
  installer_image = coalesce(var.installer_image, "ghcr.io/siderolabs/installer:${var.cluster.talos_version}")

  ips = {
    nodes = local.s1
  }

  patches = {
    static_hosts = { for key in keys(var.cluster.nodes) :
      key => [for k, ip in local.s1 : yamlencode({
        apiVersion = "v1alpha1"
        kind       = "StaticHostConfig"
        name       = ip
        hostnames  = concat(var.cluster.nodes[k].aliases, [k])
      })]
    }
    cert_sans = { for key, ip in local.s1 :
      key => yamlencode({ machine = { certSANs = [ip] } })
    }
  }
}
