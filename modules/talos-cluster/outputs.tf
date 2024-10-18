output "name" {
  value = var.name
}
output "endpoint" {
  value = var.endpoint
}

output "cluster_endpoint" {
  value = local.cluster_endpoint
}

output "patches" {
  value = local.patches
}
