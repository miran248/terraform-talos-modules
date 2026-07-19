locals {
  dev1_ipv6_image_ids = {
    scaleway = module.scaleway_image_dev["fr-par-1"].ids.image
  }
}

module "dev1_ipv6_paris_pool" {
  source = "../modules/scaleway-pool"

  prefix = "dev1-ipv6-par1"
  zone   = data.scaleway_availability_zones.paris.zones[0]

  control_planes = [
    { type = "DEV1-M", image = local.dev1_ipv6_image_ids.scaleway },
    { type = "DEV1-M", image = local.dev1_ipv6_image_ids.scaleway },
    { type = "DEV1-M", image = local.dev1_ipv6_image_ids.scaleway },
  ]
  workers = [
    { type = "DEV1-M", image = local.dev1_ipv6_image_ids.scaleway },
  ]

}

resource "scaleway_lb_ip" "dev1_ipv6" {
  zone    = data.scaleway_availability_zones.paris.zones[0]
  is_ipv6 = true
}

resource "scaleway_lb" "dev1_ipv6" {
  ip_ids = [scaleway_lb_ip.dev1_ipv6.id]
  zone   = data.scaleway_availability_zones.paris.zones[0]
  name   = "dev1-ipv6"
  type   = "LB-S"

  lifecycle {
    ignore_changes = [ip_ids]
  }
}

resource "scaleway_lb_backend" "dev1_ipv6_talos" {
  lb_id            = scaleway_lb.dev1_ipv6.id
  name             = "dev1-ipv6-talos"
  forward_protocol = "tcp"
  forward_port     = 50000
  proxy_protocol   = "none"
  server_ips       = [for k, n in module.dev1_ipv6_paris_apply.nodes : n.ip if n.kind == "control-plane"]
}

resource "scaleway_lb_frontend" "dev1_ipv6_talos" {
  lb_id        = scaleway_lb.dev1_ipv6.id
  backend_id   = scaleway_lb_backend.dev1_ipv6_talos.id
  name         = "dev1-ipv6-talos"
  inbound_port = 50000
}

resource "scaleway_lb_backend" "dev1_ipv6_k8s" {
  lb_id            = scaleway_lb.dev1_ipv6.id
  name             = "dev1-ipv6-k8s"
  forward_protocol = "tcp"
  forward_port     = 6443
  proxy_protocol   = "none"
  server_ips       = [for k, n in module.dev1_ipv6_paris_apply.nodes : n.ip if n.kind == "control-plane"]
}

resource "scaleway_lb_frontend" "dev1_ipv6_k8s" {
  lb_id        = scaleway_lb.dev1_ipv6.id
  backend_id   = scaleway_lb_backend.dev1_ipv6_k8s.id
  name         = "dev1-ipv6-k8s"
  inbound_port = 6443
}

module "dev1_ipv6_talos_cluster" {
  source = "../modules/talos-cluster"

  name               = "dev1-ipv6"
  endpoint           = scaleway_lb_ip.dev1_ipv6.ip_address
  talos_version      = "v1.14.0-alpha.1"
  kubernetes_version = "v1.36.1"

  pools = [module.dev1_ipv6_paris_pool]

  patches = {
    common = [
      # Native Cilium routing relies on KubeSpan to advertise each node's
      # predefined PodCIDR and carry it over WireGuard. Disabling bypass makes loss of
      # encryption fail closed.
      <<-EOF
        apiVersion: v1alpha1
        kind: KubeSpanConfig
        enabled: true
        advertiseKubernetesNetworks: true
        allowDownPeerBypass: false
        harvestExtraEndpoints: false
        mtu: 1420
        ---
        apiVersion: v1alpha1
        kind: LinkConfig
        name: kubespan
        routes:
          - destination: fc00:1::/96
            mtu: 1420
        ---
        apiVersion: v1alpha1
        kind: ResolverConfig
        nameservers:
          - address: 2a00:1098:2b::1 # https://nat64.net
          - address: 2a00:1098:2c::1 # https://nat64.net
          - address: 2a01:4f8:c2c:123f::1 # https://nat64.net
        ---
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

module "dev1_ipv6_paris_apply" {
  source = "../modules/scaleway-apply"

  pool    = module.dev1_ipv6_paris_pool
  cluster = module.dev1_ipv6_talos_cluster

  inbound_rules = [
    { action = "accept", protocol = "TCP", port = 443, ip_range = "::/0" },
    { action = "accept", protocol = "TCP", port = 80, ip_range = "::/0" },
  ]
}

module "dev1_ipv6_talos_apply" {
  source = "../modules/talos-apply"

  cluster         = module.dev1_ipv6_talos_cluster
  applies         = [module.dev1_ipv6_paris_apply]
  installer_image = "ghcr.io/miran248/talos-installer:v1.14.0-alpha.1-dev.7"
}

module "dev1_ipv6_gcp_wif_apply" {
  source = "../modules/gcp-wif-apply"

  identities = module.gcp_wif
  cluster    = module.dev1_ipv6_talos_cluster
  apply      = module.dev1_ipv6_talos_apply
}

output "talos_config_ipv6" {
  value     = module.dev1_ipv6_talos_cluster.talos_config
  sensitive = true
}

output "kube_config_ipv6" {
  value     = module.dev1_ipv6_talos_apply.kube_config
  sensitive = true
}
