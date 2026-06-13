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

data "talos_machine_configuration" "this" {
  for_each           = var.cluster.nodes
  cluster_endpoint   = var.cluster.cluster_endpoint
  cluster_name       = var.cluster.name
  kubernetes_version = var.cluster.kubernetes_version
  machine_secrets    = var.cluster.machine_secrets.machine_secrets
  machine_type       = each.value.talos.machine_type
  talos_version      = var.cluster.talos_version
  config_patches = concat(
    each.value.patches,
    try(local.patches.static_hosts[each.key], []),
    [local.patches.cert_sans[each.key]],
  )
}

resource "talos_machine" "control_planes" {
  for_each = { for k, ip in local.ips.nodes : k => ip if var.cluster.nodes[k].kind == "control-plane" }

  client_configuration  = var.cluster.machine_secrets.client_configuration
  endpoint              = var.cluster.endpoint
  node                  = each.value
  image                 = local.installer_image
  machine_configuration = data.talos_machine_configuration.this[each.key].machine_configuration
  drain_on_upgrade      = false
}

resource "talos_machine" "workers" {
  for_each = { for k, ip in local.ips.nodes : k => ip if var.cluster.nodes[k].kind == "worker" }

  client_configuration  = var.cluster.machine_secrets.client_configuration
  endpoint              = var.cluster.endpoint
  node                  = each.value
  image                 = local.installer_image
  machine_configuration = data.talos_machine_configuration.this[each.key].machine_configuration
  drain_on_upgrade      = false

  depends_on = [talos_machine.control_planes]
}

resource "talos_cluster" "this" {
  client_configuration = var.cluster.machine_secrets.client_configuration
  endpoint             = var.cluster.endpoint
  node                 = values({ for k, ip in local.ips.nodes : k => ip if var.cluster.nodes[k].kind == "control-plane" })[0]
  control_plane_nodes  = values({ for k, ip in local.ips.nodes : k => ip if var.cluster.nodes[k].kind == "control-plane" })
  kubernetes_version   = var.cluster.kubernetes_version

  depends_on = [talos_machine.control_planes]
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = var.cluster.machine_secrets.client_configuration
  endpoint             = var.cluster.endpoint
  node                 = values({ for k, ip in local.ips.nodes : k => ip if var.cluster.nodes[k].kind == "control-plane" })[0]

  depends_on = [talos_cluster.this]
}
