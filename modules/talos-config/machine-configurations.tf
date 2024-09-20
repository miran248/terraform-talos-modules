data "talos_machine_configuration" "this" {
  for_each           = local.network_nodes2
  cluster_endpoint   = var.cluster.cluster_endpoint
  cluster_name       = var.cluster.name
  config_patches     = each.value.patches
  kubernetes_version = var.kubernetes_version
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  machine_type       = each.value.talos.machine_type
  talos_version      = var.talos_version
}
