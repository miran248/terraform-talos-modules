resource "talos_cluster_kubeconfig" "this" {
  client_configuration = var.cluster.machine_secrets.client_configuration
  endpoint             = var.cluster.endpoint
  node                 = var.cluster.names.control_planes[0]

  depends_on = [
    talos_machine_bootstrap.this,
  ]
}
