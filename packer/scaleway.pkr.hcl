# NOTE does not work!

packer {
  required_plugins {
    scaleway = {
      source  = "github.com/scaleway/scaleway"
      version = ">= 1.1.0"
    }
  }
}

source "scaleway" "talos-amd64" {
  image = "debian_trixie"
  zone  = "fr-par-1"
  # commercial_type = "DEV1-S"
  commercial_type = "DEV1-L"
  ssh_username    = "root"
  # image_name      = "talos-v1.12.6-amd64"
  # snapshot_name   = "talos-v1.12.6-amd64"
  remove_volume = true
  tags          = ["talos", "v1.12.6", "amd64"]

  # root_volume {
  #   size_in_gb = 50
  # }

  # block_volume {
  #   size_in_gb = 25
  # }
}

build {
  sources = ["source.scaleway.talos-amd64"]
  provisioner "shell" {
    expect_disconnect   = true
    start_retry_timeout = "30s"
    timeout             = "1m"
    valid_exit_codes    = [0, 1, 2300218]
    skip_clean          = false
    inline = [
      # "ls /dev",
      # "apt-get install -y wget zstd",
      # # https://factory.talos.dev/?arch=amd64&cmdline-set=true&extensions=-&platform=scaleway&target=cloud&version=1.12.6
      # "wget -O /tmp/talos.raw.zst https://factory.talos.dev/image/376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba/v1.12.6/scaleway-amd64.raw.zst",
      # # "zstd -dvc /tmp/talos.raw.zst | dd of=/dev/sdb && sync",
      # "zstd -dvc /tmp/talos.raw.zst | dd of=/dev/sda && sync",

      "curl -sSL https://github.com/cozystack/boot-to-talos/raw/refs/heads/main/hack/install.sh | sh -s",
      # "boot-to-talos -yes -mode install -disk /dev/sda1 -image ghcr.io/cozystack/cozystack/talos:v1.12.6",
      "boot-to-talos -yes -mode boot -disk /dev/sda -image ghcr.io/cozystack/cozystack/talos:v1.12.6",
    ]
  }
}
