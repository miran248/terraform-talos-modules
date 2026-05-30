locals {
  ids = {
    bucket   = data.scaleway_object_bucket.this.id
    object   = data.scaleway_object.this.id
    snapshot = scaleway_instance_snapshot.this.id
    image    = scaleway_instance_image.this.id
  }
}
