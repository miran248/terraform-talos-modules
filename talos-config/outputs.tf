output "cluster_name" {
  value = var.cluster_name
}
output "endpoint" {
  value = var.endpoint
}

output "control_planes" {
  value = local.control_planes
}
output "workers" {
  value = local.workers
}

output "machine_secrets" {
  value = talos_machine_secrets.this
}
output "talos_config" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}
