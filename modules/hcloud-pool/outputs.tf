output "MODULE_NAME" {
  value = "hcloud-pool"
}

output "prefix" {
  value = var.prefix
}
output "location" {
  value = var.location
}

output "ids" {
  value = local.ids
}

output "nodes" {
  value = local.nodes
}
