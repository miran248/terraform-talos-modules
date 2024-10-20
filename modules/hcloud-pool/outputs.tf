output "MODULE_NAME" {
  value = "hcloud-pool"
}

output "prefix" {
  value = var.prefix
}
output "datacenter" {
  value = var.datacenter
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
