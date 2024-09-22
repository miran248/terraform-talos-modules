locals {
  single6_patches_hcloud_csi = yamlencode({
    cluster = {
      extraManifests = [
        "https://raw.githubusercontent.com/miran248/terraform-talos-modules/v1.0.0/manifests/hcloud-csi.yaml",
      ]
      inlineManifests = [
        {
          name     = "hcloud-secret",
          contents = <<-EOF
            apiVersion: v1
            kind: Secret
            metadata:
              name: hcloud
              namespace: kube-system
            stringData:
              token: ${var.hcloud_token}
            type: Opaque
          EOF
        },
      ]
    }
  })
}

module "single6_talos_cluster" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-cluster?ref=v1.0.0"

  # ...

  patches = {
    common = [
      local.single6_patches_hcloud_csi,
      # ...
    ]
  }
}

# ...
