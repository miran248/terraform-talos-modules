locals {
  dev1_image_ids = {
    hcloud   = data.hcloud_image.v1_13_3_amd64.id
    # scaleway = module.scaleway_image["fr-par-1"].ids.image
    scaleway = module.scaleway_image_dev["fr-par-1"].ids.image
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
  ]
}

resource "scaleway_lb_ip" "dev1" {
  zone    = data.scaleway_availability_zones.paris.zones[0]
  is_ipv6 = true
}

resource "scaleway_lb" "dev1" {
  ip_ids = [scaleway_lb_ip.dev1.id]
  zone   = data.scaleway_availability_zones.paris.zones[0]
  name   = "dev1"
  type   = "LB-S"
}

locals {
  dev1_control_plane_keys = [for k, v in module.dev1_talos_cluster.nodes : k if v.kind == "control-plane"]
}

resource "scaleway_lb_backend" "dev1_talos" {
  lb_id            = scaleway_lb.dev1.id
  name             = "dev1-talos"
  forward_protocol = "tcp"
  forward_port     = 50000
  proxy_protocol   = "none"
  server_ips       = [for k in local.dev1_control_plane_keys : module.dev1_paris_apply.ips.v6[k]]
}

resource "scaleway_lb_frontend" "dev1_talos" {
  lb_id        = scaleway_lb.dev1.id
  backend_id   = scaleway_lb_backend.dev1_talos.id
  name         = "dev1-talos"
  inbound_port = 50000
}

resource "scaleway_lb_backend" "dev1_k8s" {
  lb_id            = scaleway_lb.dev1.id
  name             = "dev1-k8s"
  forward_protocol = "tcp"
  forward_port     = 6443
  proxy_protocol   = "none"
  server_ips       = [for k in local.dev1_control_plane_keys : module.dev1_paris_apply.ips.v6[k]]
}

resource "scaleway_lb_frontend" "dev1_k8s" {
  lb_id        = scaleway_lb.dev1.id
  backend_id   = scaleway_lb_backend.dev1_k8s.id
  name         = "dev1-k8s"
  inbound_port = 6443
}

module "dev1_talos_cluster" {
  source = "../modules/talos-cluster"

  name               = "dev1"
  endpoint           = scaleway_lb_ip.dev1.ip_address
  talos_version      = "v1.14.0-alpha.1"
  kubernetes_version = "v1.36.1"

  pools = [
    # module.dev1_nuremberg_pool,
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
        kind: TimeSyncConfig
        ptp:
          devices:
            - /dev/ptp0
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

  inbound_rules = [
    { action = "accept", protocol = "TCP", port = 443 },
    { action = "accept", protocol = "TCP", port = 80 },
  ]
}

module "dev1_talos_apply" {
  source = "../modules/talos-apply"

  cluster = module.dev1_talos_cluster
  applies         = [module.dev1_paris_apply]
  installer_image = "ghcr.io/siderolabs/installer:v1.14.0-alpha.1-dev.7"
}

module "dev1_gcp_wif_apply" {
  source = "../modules/gcp-wif-apply"

  identities = module.gcp_wif
  cluster    = module.dev1_talos_cluster
  apply      = module.dev1_talos_apply
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
