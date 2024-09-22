packer {
  required_plugins {
    hcloud = {
      source  = "github.com/hetznercloud/hcloud"
      version = ">= 1.0.0"
    }
  }
}

source "hcloud" "talos-amd64" {
  image         = "debian-11"
  location      = "fsn1"
  rescue        = "linux64"
  server_type   = "cx22"
  ssh_username  = "root"
  snapshot_name = "talos-v1.7.6-amd64"
  snapshot_labels = {
    name    = "talos"
    version = "v1.7.6"
    arch    = "amd64"
  }
}

build {
  sources = ["source.hcloud.talos-amd64"]
  provisioner "shell" {
    inline = [
      "apt-get install -y wget",
      "wget -O /tmp/talos.raw.xz https://github.com/siderolabs/talos/releases/download/v1.7.6/hcloud-amd64.raw.xz",
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync",
    ]
  }
}
