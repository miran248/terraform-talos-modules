data "hcloud_location" "nuremberg" {
  name = "nbg1"
}
data "hcloud_location" "helsinki" {
  name = "hel1"
}

data "hcloud_image" "v1_13_3_amd64" {
  with_selector = "name=talos,version=v1.13.3,arch=amd64"
}
data "hcloud_image" "v1_14_0_alpha_1_amd64" {
  with_selector = "name=talos,version=v1.14.0-alpha.1,arch=amd64"
}
