locals {
  ids = {
    bucket   = data.scaleway_object_bucket.this.id
    object   = data.scaleway_object.this.id
    snapshot = scaleway_instance_snapshot.this.id
    image    = scaleway_instance_image.this.id
  }
}

data "scaleway_object_bucket" "this" {
  name = var.bucket
}
data "scaleway_object" "this" {
  bucket = data.scaleway_object_bucket.this.name
  key    = var.object
}
resource "scaleway_instance_snapshot" "this" {
  name = var.name
  zone = var.zone

  import {
    bucket = data.scaleway_object.this.bucket
    key    = data.scaleway_object.this.key
  }
}
resource "scaleway_instance_image" "this" {
  name           = var.name
  root_volume_id = scaleway_instance_snapshot.this.id
  zone           = var.zone
}

# TODO: figure out if it's possible to automate the file upload directly from the factory
# resource "terraform_data" "trigger" {
#   input = "trigger-a"
# }
# resource "terraform_data" "zstd" {
#   triggers_replace = [
#     terraform_data.trigger,
#   ]

#   provisioner "local-exec" {
#     command = ".."
#   }
# }
