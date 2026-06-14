packer {
  required_plugins {
    hcloud = {
      source  = "github.com/hetznercloud/hcloud"
      version = ">= 1.0.0"
    }
  }
}

variable "tag" {
  type = string
}

variable "images_path" {
  type = string
}

source "hcloud" "talos-amd64" {
  image         = "debian-12"
  location      = "fsn1"
  rescue        = "linux64"
  server_type   = "cx23"
  ssh_username  = "root"
  snapshot_name = "talos-${var.tag}-amd64"
  snapshot_labels = {
    name    = "talos"
    version = var.tag
    arch    = "amd64"
  }
}

build {
  sources = ["source.hcloud.talos-amd64"]
  provisioner "file" {
    source      = "${var.images_path}/hcloud-amd64.raw.zst"
    destination = "/tmp/talos.raw.zst"
  }
  provisioner "shell" {
    inline = [
      "zstd -d -c /tmp/talos.raw.zst | dd of=/dev/sda && sync",
    ]
  }
}
