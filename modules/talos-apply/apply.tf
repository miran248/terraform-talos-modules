# Split into two resources so workers can depend_on control_planes, enabling rolling upgrades.
resource "talos_machine" "control_planes" {
  for_each              = { for k, v in data.talos_machine_configuration.this : k => v if var.cluster.nodes[k].kind == "control-plane" }
  client_configuration  = var.cluster.machine_secrets.client_configuration
  endpoint              = var.cluster.endpoint
  node                  = each.key
  image                 = "ghcr.io/siderolabs/installer:${var.cluster.talos_version}"
  machine_configuration = each.value.machine_configuration
  drain_on_upgrade      = true
}

resource "talos_machine" "workers" {
  for_each              = { for k, v in data.talos_machine_configuration.this : k => v if var.cluster.nodes[k].kind == "worker" }
  client_configuration  = var.cluster.machine_secrets.client_configuration
  endpoint              = var.cluster.endpoint
  node                  = each.key
  image                 = "ghcr.io/siderolabs/installer:${var.cluster.talos_version}"
  machine_configuration = each.value.machine_configuration
  drain_on_upgrade      = true

  depends_on = [talos_machine.control_planes]
}
