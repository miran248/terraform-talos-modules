data "hcloud_image" "v1_8_3_amd64" {
  with_selector = "name=talos,version=v1.8.3,arch=amd64"
}
data "hcloud_image" "v1_9_0_amd64" {
  with_selector = "name=talos,version=v1.9.0-beta.0,arch=amd64"
}
data "hcloud_datacenter" "nuremberg" {
  name = "nbg1-dc3"
}
data "hcloud_datacenter" "helsinki" {
  name = "hel1-dc2"
}
