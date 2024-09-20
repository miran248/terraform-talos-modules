locals {
  single6_patches_hcloud_cni = yamlencode({
    cluster = {
      extraManifests = [
        "https://raw.githubusercontent.com/miran248/terraform-talos-modules/bc4bc43ed17857dc81931b00ac54a466119af241/manifests/hcloud-csi.yaml",
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
  source = "github.com/miran248/terraform-talos-modules//modules/talos-cluster"

  # ...

  patches = {
    common = [
      local.single6_patches_hcloud_cni,
      # ...
    ]
  }
}

# ...
