data "hcloud_image" "talos" {
  with_selector = "name=talos,version=v1.13.3,arch=amd64"
}

locals {
  image_ids = {
    hcloud = data.hcloud_image.talos.id
  }
}

module "nuremberg_pool" {
  source = "github.com/miran248/terraform-talos-modules//modules/hcloud-pool?ref=v3.2.3"

  prefix   = "nbg"
  location = "nbg1"

  control_planes = [
    { server_type = "cx22", image = local.image_ids.hcloud },
  ]
  workers = [
    { server_type = "cx22", image = local.image_ids.hcloud },
  ]
}

module "talos_cluster" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-cluster?ref=v3.2.3"

  name               = "example"
  endpoint           = "example.example.com"
  talos_version      = "v1.13.3"
  kubernetes_version = "v1.36.1"

  pools = [
    module.nuremberg_pool,
  ]

  patches = {
    common = [
      <<-EOF
        cluster:
          network:
            cni:
              name: none
          inlineManifests:
            - name: hcloud-secret
              contents: |
                apiVersion: v1
                kind: Secret
                metadata:
                  name: hcloud
                  namespace: kube-system
                stringData:
                  token: ${var.hcloud_token}
                type: Opaque
      EOF
      ,
      <<-EOF
        apiVersion: v1alpha1
        kind: ResolverConfig
        nameservers:
          - address: 2a00:1098:2b::1 # https://nat64.net
          - address: 2a00:1098:2c::1 # https://nat64.net
          - address: 2a01:4f8:c2c:123f::1 # https://nat64.net
      EOF
      ,
      <<-EOF
        apiVersion: v1alpha1
        kind: TimeSyncConfig
        ptp:
          devices:
            - /dev/ptp0
      EOF
      ,
    ]
  }
}

module "nuremberg_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/hcloud-apply?ref=v3.2.3"

  pool    = module.nuremberg_pool
  cluster = module.talos_cluster
}

module "talos_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-apply?ref=v3.2.3"

  cluster = module.talos_cluster
  applies = [module.nuremberg_apply]
}

locals {
  ips = {
    v6 = module.nuremberg_apply.ips.v6
  }
}


resource "google_dns_record_set" "control_planes" {
  name         = "${module.talos_cluster.name}.${data.google_dns_managed_zone.this.dns_name}"
  managed_zone = data.google_dns_managed_zone.this.name
  type         = "AAAA"
  ttl          = 300

  rrdatas = values({ for k, v in local.ips.v6 : k => v if module.talos_cluster.nodes[k].kind == "control-plane" })
}

# outputs
output "talos_config" {
  value     = module.talos_cluster.talos_config
  sensitive = true
}
output "kube_config" {
  value     = module.talos_apply.kube_config
  sensitive = true
}
