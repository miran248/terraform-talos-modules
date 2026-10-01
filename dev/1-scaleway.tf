# module "scaleway_image" {
#   for_each = toset(["fr-par-1"])
#   source   = "../modules/scaleway-image"

#   zone   = each.key
#   bucket = "miran248-terraform-talos-modules-dev-images"
#   object = "talos-1.13.3-amd64.qcow2"
#   name   = "talos-1.13.3-amd64"
# }
module "scaleway_image_dev" {
  for_each = toset(["fr-par-1"])
  source   = "../modules/scaleway-image"

  zone   = each.key
  bucket = "miran248-terraform-talos-modules-dev-images"
  object = "talos-v1.15.0-alpha.0-dev.2-amd64.qcow2"
  name   = "talos-v1.15.0-alpha.0-dev.2-amd64"

}
