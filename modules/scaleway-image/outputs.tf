output "MODULE_NAME" {
  value = "scaleway-image"
}

output "zone" {
  value = var.zone
}

output "bucket" {
  value = var.bucket
}
output "object" {
  value = var.object
}
output "name" {
  value = var.name
}

output "ids" {
  value = {
    bucket   = data.scaleway_object_bucket.this.id
    object   = data.scaleway_object.this.id
    snapshot = scaleway_instance_snapshot.this.id
    image    = scaleway_instance_image.this.id
  }
}
