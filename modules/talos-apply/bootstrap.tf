resource "talos_machine_bootstrap" "this" {
  client_configuration = var.cluster.machine_secrets.client_configuration
  endpoint             = var.cluster.endpoint
  node                 = var.cluster.names.control_planes[0]
}
