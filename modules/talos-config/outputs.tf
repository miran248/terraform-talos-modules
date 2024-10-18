output "machine_secrets" {
  value = talos_machine_secrets.this
}
output "talos_config" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "names" {
  value = local.names
}
output "public_ips6" {
  value = local.public_ips6
}
output "nodes" {
  value = local.nodes
}
