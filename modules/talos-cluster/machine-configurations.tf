data "talos_machine_configuration" "this" {
  for_each           = local.nodes
  cluster_endpoint   = local.cluster_endpoint
  cluster_name       = var.name
  config_patches     = each.value.patches
  kubernetes_version = var.kubernetes_version
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  machine_type       = each.value.talos.machine_type
  talos_version      = var.talos_version
}
