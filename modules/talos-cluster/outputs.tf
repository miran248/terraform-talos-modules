output "MODULE_NAME" {
  value = "talos-cluster"
}

output "name" {
  value = var.name
}
output "endpoint" {
  value = var.endpoint
}

output "cluster_endpoint" {
  value = local.cluster_endpoint
}
output "machine_secrets" {
  value = talos_machine_secrets.this
}
output "talos_config" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "nodes" {
  value = local.nodes
}

output "names" {
  value = local.names
}
output "public_ips6" {
  value = local.public_ips6
}
output "configs" {
  value = local.configs
}
