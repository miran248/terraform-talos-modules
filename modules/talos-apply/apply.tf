resource "talos_machine_configuration_apply" "this" {
  for_each                    = var.config.nodes
  client_configuration        = var.config.machine_secrets.client_configuration
  endpoint                    = var.cluster.endpoint
  machine_configuration_input = each.value.data
  # node                        = each.key
  node = each.value.name # node might be in a different network from control planes

  depends_on = [
    talos_machine_bootstrap.this,
  ]
}
