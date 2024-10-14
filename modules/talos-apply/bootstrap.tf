resource "talos_machine_bootstrap" "this" {
  client_configuration = var.config.machine_secrets.client_configuration
  endpoint             = var.cluster.endpoint
  node                 = var.config.names.control_planes[0]
}
