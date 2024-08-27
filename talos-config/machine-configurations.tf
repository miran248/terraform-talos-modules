data "talos_machine_configuration" "control_planes" {
  for_each           = local.pools.control_planes
  cluster_endpoint   = local.cluster_endpoint
  cluster_name       = var.cluster_name
  config_patches     = local.patches.control_planes[each.key]
  kubernetes_version = var.kubernetes_version
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  machine_type       = "controlplane"
  talos_version      = var.talos_version
}

data "talos_machine_configuration" "workers" {
  for_each           = local.pools.workers
  cluster_endpoint   = local.cluster_endpoint
  cluster_name       = var.cluster_name
  config_patches     = local.patches.workers[each.key]
  kubernetes_version = var.kubernetes_version
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  machine_type       = "worker"
  talos_version      = var.talos_version
}
