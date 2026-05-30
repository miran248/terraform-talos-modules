resource "talos_cluster" "this" {
  client_configuration = var.cluster.machine_secrets.client_configuration
  endpoint             = var.cluster.endpoint
  node                 = values(local.ips.control_planes)[0]
  kubernetes_version   = var.cluster.kubernetes_version
  control_plane_nodes  = values(local.ips.control_planes)

  depends_on = [talos_machine_bootstrap.this]
}
