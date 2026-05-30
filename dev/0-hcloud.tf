data "hcloud_location" "nuremberg" {
  name = "nbg1"
}
data "hcloud_location" "helsinki" {
  name = "hel1"
}

data "hcloud_image" "v1_13_3_amd64" {
  with_selector = "name=talos,version=v1.13.3,arch=amd64"
}
