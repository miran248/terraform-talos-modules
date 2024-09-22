terraform {
  cloud {
    organization = "miran248"

    workspaces {
      name = "terraform-talos-modules"
    }
  }
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    hcloud = {
      source = "hetznercloud/hcloud"
    }
    tfe = {
      source = "hashicorp/tfe"
    }
  }
  required_version = ">= 1"
}
