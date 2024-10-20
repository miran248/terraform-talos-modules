resource "talos_machine_configuration_apply" "this" {
  for_each                    = var.cluster.configs
  client_configuration        = var.cluster.machine_secrets.client_configuration
  endpoint                    = var.cluster.endpoint
  machine_configuration_input = each.value
  node                        = each.key

  depends_on = [
    talos_machine_bootstrap.this,
  ]
}
