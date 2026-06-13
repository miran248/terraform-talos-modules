resource "talos_machine" "control_planes" {
  for_each = { for k, ip in local.ips.nodes : k => ip if var.cluster.nodes[k].kind == "control-plane" }

  client_configuration  = var.cluster.machine_secrets.client_configuration
  endpoint              = var.cluster.endpoint
  node                  = each.value
  image                 = local.installer_image
  machine_configuration = data.talos_machine_configuration.this[each.key].machine_configuration
  drain_on_upgrade      = false
}

resource "talos_machine" "workers" {
  for_each = { for k, ip in local.ips.nodes : k => ip if var.cluster.nodes[k].kind == "worker" }

  client_configuration  = var.cluster.machine_secrets.client_configuration
  endpoint              = var.cluster.endpoint
  node                  = each.value
  image                 = local.installer_image
  machine_configuration = data.talos_machine_configuration.this[each.key].machine_configuration
  drain_on_upgrade      = false

  depends_on = [talos_machine.control_planes]
}
