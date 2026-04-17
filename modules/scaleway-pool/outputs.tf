output "MODULE_NAME" {
  value = "scaleway-pool"
}

output "prefix" {
  value = var.prefix
}
output "zone" {
  value = var.zone
}

output "ids" {
  value = local.ids
}

output "control_planes" {
  value = local.control_planes
}
output "workers" {
  value = local.workers
}
output "nodes" {
  value = local.nodes
}
