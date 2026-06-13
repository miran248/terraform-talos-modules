module "scaleway_image" {
  source   = "github.com/miran248/terraform-talos-modules//modules/scaleway-image?ref=v3.2.3"
  for_each = toset(["fr-par-1"])

  zone    = each.key
  version = "v1.14.0"
}

locals {
  image_ids = {
    scaleway = module.scaleway_image["fr-par-1"].ids.image
  }

  paris_zone = "fr-par-1"
}

module "paris_pool" {
  source = "github.com/miran248/terraform-talos-modules//modules/scaleway-pool?ref=v3.2.3"

  prefix = "par1"
  zone   = local.paris_zone

  control_planes = [
    { type = "DEV1-M", image = local.image_ids.scaleway },
    { type = "DEV1-M", image = local.image_ids.scaleway },
    { type = "DEV1-M", image = local.image_ids.scaleway },
  ]
  workers = [
    { type = "DEV1-M", image = local.image_ids.scaleway },
  ]
}

resource "scaleway_lb_ip" "this" {
  zone    = local.paris_zone
  is_ipv6 = true
}

resource "scaleway_lb" "this" {
  ip_ids = [scaleway_lb_ip.this.id]
  zone   = local.paris_zone
  name   = "example"
  type   = "LB-S"
}

locals {
  control_plane_keys = [for k, v in module.talos_cluster.nodes : k if v.kind == "control-plane"]
}

resource "scaleway_lb_backend" "talos" {
  lb_id            = scaleway_lb.this.id
  name             = "talos"
  forward_protocol = "tcp"
  forward_port     = 50000
  proxy_protocol   = "none"
  server_ips       = [for k in local.control_plane_keys : module.paris_apply.ips.v6[k]]
}

resource "scaleway_lb_frontend" "talos" {
  lb_id        = scaleway_lb.this.id
  backend_id   = scaleway_lb_backend.talos.id
  name         = "talos"
  inbound_port = 50000
}

resource "scaleway_lb_backend" "k8s" {
  lb_id            = scaleway_lb.this.id
  name             = "k8s"
  forward_protocol = "tcp"
  forward_port     = 6443
  proxy_protocol   = "none"
  server_ips       = [for k in local.control_plane_keys : module.paris_apply.ips.v6[k]]
}

resource "scaleway_lb_frontend" "k8s" {
  lb_id        = scaleway_lb.this.id
  backend_id   = scaleway_lb_backend.k8s.id
  name         = "k8s"
  inbound_port = 6443
}

module "talos_cluster" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-cluster?ref=v3.2.3"

  name               = "example"
  endpoint           = scaleway_lb_ip.this.ip_address
  talos_version      = "v1.14.0"
  kubernetes_version = "v1.36.1"

  pools = [
    module.paris_pool,
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
    control_planes = [
      <<-EOF
        cluster:
          allowSchedulingOnControlPlanes: true
      EOF
    ]
  }
}

module "paris_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/scaleway-apply?ref=v3.2.3"

  pool    = module.paris_pool
  cluster = module.talos_cluster
}

module "talos_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-apply?ref=v3.2.3"

  cluster = module.talos_cluster
  applies = [module.paris_apply]
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
