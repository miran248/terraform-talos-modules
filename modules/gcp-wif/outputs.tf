output "MODULE_NAME" {
  value = "gcp-wif"
}

output "name" {
  value = var.name
}
output "bucket_name" {
  value = var.bucket_name
}
output "bucket_location" {
  value = var.bucket_location
}

output "ids" {
  value = local.ids
}

output "patches" {
  value = local.patches
}
