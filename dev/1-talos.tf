locals {
  dev1_image_ids = {
    hcloud   = data.hcloud_image.v1_13_3_amd64.id
    scaleway = module.scaleway_image["fr-par-1"].ids.image
  }
}

# module "dev1_nuremberg_pool" {
#   source = "../modules/hcloud-pool"

#   prefix   = "dev1-nbg"
#   location = data.hcloud_location.nuremberg.name

#   control_planes = [
#     { server_type = "cx23", image = local.dev1_image_ids.hcloud },
#     { server_type = "cx23", image = local.dev1_image_ids.hcloud },
#     { server_type = "cx23", image = local.dev1_image_ids.hcloud },
#   ]
#   workers = [
#     # { server_type = "cx23", image = local.dev1_image_ids.hcloud },
#     # { server_type = "cx23", image = local.dev1_image_ids.hcloud },
#     # { server_type = "cx23", image = local.dev1_image_ids.hcloud },
#   ]
# }
# module "dev1_helsinki_pool" {
#   source = "../modules/hcloud-pool"

#   prefix   = "dev1-hel"
#   location = data.hcloud_location.helsinki.name

#   workers = [
#     { server_type = "cx23", image = local.dev1_image_ids.hcloud },
#     # { server_type = "cx23", image = local.dev1_image_ids.hcloud },
#   ]
# }
module "dev1_paris_pool" {
  source = "../modules/scaleway-pool"

  prefix = "dev1-par1"
  zone   = data.scaleway_availability_zones.paris.zones[0]

  control_planes = [
    { type = "DEV1-M", image = local.dev1_image_ids.scaleway },
    { type = "DEV1-M", image = local.dev1_image_ids.scaleway },
    { type = "DEV1-M", image = local.dev1_image_ids.scaleway },
  ]
  workers = [
    # { type = "DEV1-M", image = local.dev1_image_ids.scaleway },
    # { type = "DEV1-M", image = local.dev1_image_ids.scaleway },
    # { type = "DEV1-M", image = local.dev1_image_ids.scaleway },
  ]
}

module "dev1_talos_cluster" {
  source = "../modules/talos-cluster"

  name               = "dev1"
  endpoint           = "dev1.dev.248.sh"
  talos_version      = "v1.13.3"
  kubernetes_version = "v1.36.1"

  pools = [
    # module.dev1_nuremberg_pool,
    # module.dev1_helsinki_pool,
    module.dev1_paris_pool,
  ]

  patches = {
    common = [
      <<-EOF
        cluster:
          network:
            cni:
              name: none
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
    control_planes = flatten([
      module.gcp_wif.patches.control_planes,
      <<-EOF
        cluster:
          allowSchedulingOnControlPlanes: true
      EOF
    ])
  }
}

# module "dev1_nuremberg_apply" {
#   source = "../modules/hcloud-apply"

#   pool    = module.dev1_nuremberg_pool
#   cluster = module.dev1_talos_cluster
# }

module "dev1_paris_apply" {
  source = "../modules/scaleway-apply"

  pool    = module.dev1_paris_pool
  cluster = module.dev1_talos_cluster
}

module "dev1_talos_apply" {
  source = "../modules/talos-apply"

  cluster = module.dev1_talos_cluster
  applies = [module.dev1_paris_apply]
}

module "dev1_gcp_wif_apply" {
  source = "../modules/gcp-wif-apply"

  identities = module.gcp_wif
  cluster    = module.dev1_talos_cluster
  apply      = module.dev1_talos_apply
}

locals {
  dev1_ips = {
    v6 = module.dev1_paris_apply.ips.v6
    v4 = module.dev1_paris_apply.ips.v4
  }
}


resource "google_dns_record_set" "dev1_control_planes" {
  name         = "${module.dev1_talos_cluster.name}.${data.google_dns_managed_zone.this.dns_name}"
  managed_zone = data.google_dns_managed_zone.this.name
  type         = "AAAA"
  ttl          = 300

  rrdatas = values({ for k, v in local.dev1_ips.v6 : k => v if module.dev1_talos_cluster.nodes[k].kind == "control-plane" })
}

resource "google_dns_record_set" "dev1_control_planes_v4" {
  name         = "${module.dev1_talos_cluster.name}.${data.google_dns_managed_zone.this.dns_name}"
  managed_zone = data.google_dns_managed_zone.this.name
  type         = "A"
  ttl          = 300

  rrdatas = values({ for k, v in local.dev1_ips.v4 : k => v if module.dev1_talos_cluster.nodes[k].kind == "control-plane" })
}

# outputs
output "talos_config" {
  value     = module.dev1_talos_cluster.talos_config
  sensitive = true
}
output "kube_config" {
  value     = module.dev1_talos_apply.kube_config
  sensitive = true
}
