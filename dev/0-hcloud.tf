data "hcloud_location" "nuremberg" {
  name = "nbg1"
}
data "hcloud_location" "helsinki" {
  name = "hel1"
}

data "hcloud_image" "v1_14_0_alpha_1_dev_7_amd64" {
  with_selector = "name=talos,version=v1.14.0-alpha.1-dev.7,arch=amd64"
}
