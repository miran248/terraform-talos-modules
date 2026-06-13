resource "talos_cluster" "this" {
  client_configuration = var.cluster.machine_secrets.client_configuration
  endpoint             = var.cluster.endpoint
  node                 = values({ for k, ip in local.ips.nodes : k => ip if var.cluster.nodes[k].kind == "control-plane" })[0]
  control_plane_nodes  = values({ for k, ip in local.ips.nodes : k => ip if var.cluster.nodes[k].kind == "control-plane" })
  kubernetes_version   = var.cluster.kubernetes_version

  depends_on = [talos_machine.control_planes]
}
