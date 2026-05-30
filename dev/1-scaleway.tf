module "scaleway_image" {
  for_each = toset(["fr-par-1"])
  source   = "../modules/scaleway-image"

  zone   = each.key
  bucket = "miran248-terraform-talos-modules-dev-images"
  object = "talos-1.13.3-amd64.qcow2"
  name   = "talos-1.13.3-amd64"
}
