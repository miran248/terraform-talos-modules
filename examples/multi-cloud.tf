data "hcloud_image" "talos" {
  with_selector = "name=talos,version=v1.14.0,arch=amd64"
}

module "scaleway_image" {
  source   = "github.com/miran248/terraform-talos-modules//modules/scaleway-image?ref=v4.2.1"
  for_each = toset(["fr-par-1"])

  zone   = each.key
  bucket = "my-talos-images"
  object = "talos-v1.14.0-amd64.qcow2"
  name   = "talos-v1.14.0-amd64"
}

module "paris_pool" {
  source = "github.com/miran248/terraform-talos-modules//modules/scaleway-pool?ref=v4.2.1"

  prefix = "par1"
  zone   = "fr-par-1"

  control_planes = [
    { type = "DEV1-M", image = module.scaleway_image["fr-par-1"].ids.image },
    { type = "DEV1-M", image = module.scaleway_image["fr-par-1"].ids.image },
    { type = "DEV1-M", image = module.scaleway_image["fr-par-1"].ids.image },
  ]
}

module "nuremberg_pool" {
  source = "github.com/miran248/terraform-talos-modules//modules/hcloud-pool?ref=v4.2.1"

  prefix   = "nbg"
  location = "nbg1"

  workers = [
    { server_type = "cx23", image = data.hcloud_image.talos.id },
    { server_type = "cx23", image = data.hcloud_image.talos.id },
  ]
}

resource "scaleway_lb_ip" "this" {
  zone    = "fr-par-1"
  is_ipv6 = true
}

resource "scaleway_lb" "this" {
  ip_ids = [scaleway_lb_ip.this.id]
  zone   = "fr-par-1"
  name   = "example"
  type   = "LB-S"
}

resource "scaleway_lb_backend" "talos" {
  lb_id            = scaleway_lb.this.id
  name             = "talos"
  forward_protocol = "tcp"
  forward_port     = 50000
  proxy_protocol   = "none"
  server_ips       = [for k, n in module.paris_apply.nodes : n.ip if n.kind == "control-plane"]
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
  server_ips       = [for k, n in module.paris_apply.nodes : n.ip if n.kind == "control-plane"]
}

resource "scaleway_lb_frontend" "k8s" {
  lb_id        = scaleway_lb.this.id
  backend_id   = scaleway_lb_backend.k8s.id
  name         = "k8s"
  inbound_port = 6443
}

module "talos_cluster" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-cluster?ref=v4.2.1"

  name               = "example"
  endpoint           = scaleway_lb_ip.this.ip_address
  talos_version      = "v1.14.0"
  kubernetes_version = "v1.36.1"

  pools = [
    module.paris_pool,
    module.nuremberg_pool,
  ]

  patches = {
    common = [
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
    control_planes = [
      <<-EOF
        cluster:
          allowSchedulingOnControlPlanes: true
      EOF
      ,
    ]
  }
}

module "paris_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/scaleway-apply?ref=v4.2.1"

  pool    = module.paris_pool
  cluster = module.talos_cluster
}

module "nuremberg_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/hcloud-apply?ref=v4.2.1"

  pool    = module.nuremberg_pool
  cluster = module.talos_cluster
}

module "talos_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-apply?ref=v4.2.1"

  cluster = module.talos_cluster
  applies = [module.paris_apply, module.nuremberg_apply]
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
