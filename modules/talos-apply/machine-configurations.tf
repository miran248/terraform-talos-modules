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
