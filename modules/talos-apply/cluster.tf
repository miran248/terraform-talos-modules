resource "talos_cluster_kubeconfig" "this" {
  client_configuration = var.cluster.machine_secrets.client_configuration
  endpoint             = var.cluster.endpoint
  node                 = values({ for k, ip in local.ips.nodes : k => ip if var.cluster.nodes[k].kind == "control-plane" })[0]

  depends_on = [talos_cluster.this]
}
