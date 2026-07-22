data "hcloud_image" "talos" {
  with_selector = "name=talos,version=v1.14.0,arch=amd64"
}

module "nuremberg_pool" {
  source = "github.com/miran248/terraform-talos-modules//modules/hcloud-pool?ref=v4.2.2" # x-release-please-version

  prefix   = "nbg"
  location = "nbg1"

  control_planes = [
    { server_type = "cx23", image = data.hcloud_image.talos.id },
  ]
  workers = [
    { server_type = "cx23", image = data.hcloud_image.talos.id },
  ]
}

module "talos_cluster" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-cluster?ref=v4.2.2" # x-release-please-version

  name               = "example"
  endpoint           = "example.example.com"
  talos_version      = "v1.14.0"
  kubernetes_version = "v1.36.1"

  pools = [
    module.nuremberg_pool,
  ]

  patches = {
    common = [
      <<-EOF
        cluster:
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
  source = "github.com/miran248/terraform-talos-modules//modules/hcloud-apply?ref=v4.2.2" # x-release-please-version

  pool    = module.nuremberg_pool
  cluster = module.talos_cluster
}

module "talos_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-apply?ref=v4.2.2" # x-release-please-version

  cluster = module.talos_cluster
  applies = [module.nuremberg_apply]
}

resource "google_dns_record_set" "control_planes" {
  name         = "${module.talos_cluster.name}.${data.google_dns_managed_zone.this.dns_name}"
  managed_zone = data.google_dns_managed_zone.this.name
  type         = "AAAA"
  ttl          = 300

  rrdatas = [for k, n in module.nuremberg_apply.nodes : n.ip if n.kind == "control-plane"]
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
