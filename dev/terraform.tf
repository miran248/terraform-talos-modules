terraform {
  cloud {
    organization = "miran248"

    workspaces {
      name = "dev"
    }
  }
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    scaleway = {
      source = "scaleway/scaleway"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.12.0-alpha.3"
    }
  }
  required_version = ">= 1"
}
