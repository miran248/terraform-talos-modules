locals {
  nodes           = merge([for a in var.applies : a.nodes]...)
  installer_image = coalesce(var.installer_image, "ghcr.io/siderolabs/installer:${var.cluster.talos_version}")

  patches = {
    static_hosts = { for key in keys(local.nodes) :
      key => [for k, n in local.nodes : yamlencode({
        apiVersion = "v1alpha1"
        kind       = "StaticHostConfig"
        name       = n.ip
        hostnames  = concat(var.cluster.nodes[k].aliases, [k])
      })]
    }
    cert_sans = { for key, n in local.nodes :
      key => yamlencode({ machine = { certSANs = [n.ip] } })
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
    local.patches.static_hosts[each.key],
    [local.patches.cert_sans[each.key]],
  )
}

# not necessary but allows talos_machine resources to be created before talos_cluster finishes
ephemeral "talos_cluster_kubeconfig" "drain" {
  cluster_name    = var.cluster.name
  machine_secrets = var.cluster.machine_secrets.machine_secrets
  endpoint        = var.cluster.cluster_endpoint
}

resource "talos_machine" "control_planes" {
  for_each = { for k, n in local.nodes : k => n if n.kind == "control-plane" }

  client_configuration  = var.cluster.machine_secrets.client_configuration
  endpoint              = var.cluster.endpoint
  node                  = each.value.ip
  image                 = local.installer_image
  machine_configuration = data.talos_machine_configuration.this[each.key].machine_configuration
  drain_on_upgrade      = var.drain_on_upgrade
  kubeconfig_wo         = ephemeral.talos_cluster_kubeconfig.drain.kubeconfig_raw
}

resource "talos_machine" "workers" {
  for_each = { for k, n in local.nodes : k => n if n.kind == "worker" }

  client_configuration  = var.cluster.machine_secrets.client_configuration
  endpoint              = var.cluster.endpoint
  node                  = each.value.ip
  image                 = local.installer_image
  machine_configuration = data.talos_machine_configuration.this[each.key].machine_configuration
  drain_on_upgrade      = var.drain_on_upgrade
  kubeconfig_wo         = ephemeral.talos_cluster_kubeconfig.drain.kubeconfig_raw

  depends_on = [talos_machine.control_planes]
}

resource "talos_cluster" "this" {
  client_configuration = var.cluster.machine_secrets.client_configuration
  endpoint             = var.cluster.endpoint
  control_plane_nodes  = values({ for k, n in local.nodes : k => n.ip if n.kind == "control-plane" })
  node                 = values({ for k, n in local.nodes : k => n.ip if n.kind == "control-plane" })[0]
  kubernetes_version   = var.cluster.kubernetes_version
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = var.cluster.machine_secrets.client_configuration
  endpoint             = var.cluster.endpoint
  node                 = values({ for k, n in local.nodes : k => n.ip if n.kind == "control-plane" })[0]

  depends_on = [talos_cluster.this]
}
