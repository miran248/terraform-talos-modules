resource "talos_cluster_kubeconfig" "this" {
  client_configuration = var.config.machine_secrets.client_configuration
  endpoint             = var.cluster.endpoint
  node                 = var.config.private_ips4.control_planes[0]

  depends_on = [
    talos_machine_bootstrap.this,
  ]
}
