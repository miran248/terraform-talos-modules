packer {
  required_plugins {
    hcloud = {
      source  = "github.com/hetznercloud/hcloud"
      version = ">= 1.0.0"
    }
  }
}

source "hcloud" "talos-amd64" {
  image         = "debian-12"
  location      = "fsn1"
  rescue        = "linux64"
  server_type   = "cx23"
  ssh_username  = "root"
  snapshot_name = "talos-v1.13.3-amd64"
  snapshot_labels = {
    name    = "talos"
    version = "v1.13.3"
    arch    = "amd64"
  }
}

build {
  sources = ["source.hcloud.talos-amd64"]
  provisioner "shell" {
    inline = [
      "apt-get install -y wget",
      # https://factory.talos.dev/?arch=amd64&platform=hcloud&schematic-id=376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba&target=cloud&version=1.13.3
      "wget -O /tmp/talos.raw.xz https://factory.talos.dev/image/376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba/v1.13.3/hcloud-amd64.raw.xz",
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync",
    ]
  }
}
