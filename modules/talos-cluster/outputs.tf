output "name" {
  value = var.name
}
output "endpoint" {
  value = var.endpoint
}
output "features" {
  value = var.features
}

output "cluster_endpoint" {
  value = local.cluster_endpoint
}
# output "cidrs6" {
#   value = local.cidrs6
# }
# output "cidrs4" {
#   value = local.cidrs4
# }

output "patches" {
  value = local.patches
}
