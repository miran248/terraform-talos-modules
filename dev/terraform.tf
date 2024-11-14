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
  }
  required_version = ">= 1"
}
