output "MODULE_NAME" {
  value = "scaleway-pool"
}

output "prefix" {
  value = var.prefix
}
output "zone" {
  value = var.zone
}

output "mode" {
  value = var.mode
}

output "ids" {
  value = local.ids
}

output "nodes" {
  value = local.nodes
}
