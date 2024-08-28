resource "talos_machine_configuration_apply" "control_planes" {
  for_each                    = var.config.control_planes
  client_configuration        = var.config.machine_secrets.client_configuration
  config_patches              = each.value.patches
  endpoint                    = var.config.endpoint
  machine_configuration_input = each.value.machine_configuration
  node                        = each.key

  depends_on = [
    talos_machine_bootstrap.this,
  ]
}

resource "talos_machine_configuration_apply" "workers" {
  for_each                    = var.config.workers
  client_configuration        = var.config.machine_secrets.client_configuration
  config_patches              = each.value.patches
  endpoint                    = var.config.endpoint
  machine_configuration_input = each.value.machine_configuration
  node                        = each.key

  depends_on = [
    talos_machine_configuration_apply.control_planes,
  ]
}
