resource "talos_machine_bootstrap" "this" {
  client_configuration = var.config.machine_secrets.client_configuration
  endpoint             = var.config.endpoint
  node                 = keys(var.config.control_planes)[0]
}
