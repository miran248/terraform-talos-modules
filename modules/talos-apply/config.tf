resource "talos_cluster_kubeconfig" "this" {
  client_configuration = var.cluster.machine_secrets.client_configuration
  endpoint             = var.cluster.endpoint
  node                 = [for k, v in var.cluster.nodes : k if v.kind == "control-plane"][0]

  depends_on = [
    talos_cluster.this,
  ]
}
