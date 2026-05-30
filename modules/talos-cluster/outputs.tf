output "MODULE_NAME" {
  value = "talos-cluster"
}

output "name" {
  value = var.name
}
output "endpoint" {
  value = local.endpoint
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

output "configs" {
  value = local.configs
}

output "talos_version" {
  value = var.talos_version
}
output "kubernetes_version" {
  value = var.kubernetes_version
}
