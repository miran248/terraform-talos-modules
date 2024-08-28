output "cloud" {
  value = var.cloud
}
output "region" {
  value = var.region
}
output "zone" {
  value = var.zone
}

output "cidrs4" {
  value = local.cidrs4
}
output "ips4" {
  value = local.ips4
}
# output "cidrs6" {
#   value = local.cidrs6
# }
# output "ips6" {
#   value = local.ips6
# }
