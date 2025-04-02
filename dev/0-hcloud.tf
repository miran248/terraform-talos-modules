data "hcloud_image" "v1_9_5_amd64" {
  with_selector = "name=talos,version=v1.9.5,arch=amd64"
}
data "hcloud_datacenter" "nuremberg" {
  name = "nbg1-dc3"
}
data "hcloud_datacenter" "helsinki" {
  name = "hel1-dc2"
}
