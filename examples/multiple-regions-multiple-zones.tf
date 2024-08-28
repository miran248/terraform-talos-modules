data "hcloud_image" "v1_7_6_amd64" {
  with_selector = "name=talos,version=v1.7.6,arch=amd64"
}

data "hcloud_datacenter" "nuremberg" {
  name = "nbg1-dc3"
}
data "hcloud_location" "nuremberg" {
  name = "nbg1"
}

data "hcloud_datacenter" "falkenstein" {
  name = "fsn1-dc14"
}
data "hcloud_location" "falkenstein" {
  name = "fsn1"
}

locals {
  cluster_name = "example"
  endpoint     = "k.example.com"

  hcloud_router = <<-USER_DATA
    #cloud-config
    packages:
      - ifupdown
    package_update: true
    package_upgrade: true
    runcmd:
      - |
        cat <<'EOF' >> /etc/network/interfaces
        auto eth0
        iface eth0 inet dhcp
            dns-nameservers 185.12.64.1 185.12.64.2
            post-up echo 1 > /proc/sys/net/ipv4/ip_forward
            post-up iptables -t nat -A POSTROUTING -s '${module.layout.cidrs4.network}' -o eth0 -j MASQUERADE
        EOF
      - reboot
  USER_DATA

  hcloud_router_client = <<-USER_DATA
    #cloud-config
    packages:
      - ifupdown
    package_update: true
    package_upgrade: true
    runcmd:
      - |
        cat <<'EOF' >> /etc/network/interfaces
        auto enp7s0
        iface enp7s0 inet dhcp
            dns-nameservers 185.12.64.1 185.12.64.2
            post-up ip route add default via ${module.layout.ips4.gateways.network}
        EOF
      - reboot
  USER_DATA

  patches_hcloud  = <<-EOF
    cluster:
      network:
        cni:
          name: none
    machine:
      network:
        kubespan:
          enabled: true
          advertiseKubernetesNetworks: false
          mtu: 1370 # Hcloud has a MTU of 1450 (KubeSpanMTU = UnderlyingMTU - 80)
        interfaces:
          - interface: eth0
            dhcp: true
            routes:
              - network: 172.31.1.1/32
              - network: 0.0.0.0/0
                gateway: 172.31.1.1
        nameservers:
          - 185.12.64.1
          - 185.12.64.2
  EOF
  patches_zitadel = <<-EOF
    machine:
      nodeLabels:
        app: zitadel
  EOF

  nodes_nuremberg = [
    {
      control_planes = [
        { server_type = "cx22" },
        { server_type = "cx22" },
        { server_type = "cx22" },
      ]
      workers = [
        { server_type = "cx22", patches = [local.patches_zitadel] },
        { server_type = "cx22", patches = [local.patches_zitadel] },
        { server_type = "cx22", patches = [local.patches_zitadel] },
        { removed = true, server_type = "cx22" },
        { server_type = "cx22" },
      ]
    },
    {
      workers = [
        { server_type = "cx22" },
        { server_type = "cx22" },
      ]
    },
  ]
  nodes_falkenstein = [
    {
      workers = [
        { server_type = "cx22" },
        { server_type = "cx22" },
        { server_type = "cx22" },
      ]
    },
    {
      workers = [
        { server_type = "cx22" },
        { server_type = "cx22" },
        { server_type = "cx22" },
      ]
    },
  ]
}

module "layout" {
  source = "github.com/miran248/terraform-talos-modules//modules/network-layout"
}

module "zones_nuremberg" {
  count  = length(local.nodes_nuremberg)
  source = "github.com/miran248/terraform-talos-modules//modules/network-zone"

  cloud  = 1
  region = 1
  zone   = 1 + count.index
}
module "zones_falkenstein" {
  count  = length(local.nodes_falkenstein)
  source = "github.com/miran248/terraform-talos-modules//modules/network-zone"

  cloud  = 1
  region = 2
  zone   = 1 + count.index
}

module "pools_nuremberg" {
  count  = length(local.nodes_nuremberg)
  source = "github.com/miran248/terraform-talos-modules//modules/node-pool"

  prefix = "nuremberg"
  zone   = module.zones_nuremberg[count.index]
  nodes  = local.nodes_nuremberg[count.index]

  patches = {
    control_planes = [local.patches_hcloud]
    workers        = [local.patches_hcloud]
  }
}
module "pools_falkenstein" {
  count  = length(local.nodes_falkenstein)
  source = "github.com/miran248/terraform-talos-modules//modules/node-pool"

  prefix = "falkenstein"
  zone   = module.zones_falkenstein[count.index]
  nodes  = local.nodes_falkenstein[count.index]

  patches = {
    control_planes = [local.patches_hcloud]
    workers        = [local.patches_hcloud]
  }
}

module "talos_config" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-config"

  layout = module.layout
  pools = flatten([
    module.pools_nuremberg,
    module.pools_falkenstein,
  ])

  cluster_name = local.cluster_name
  endpoint     = local.endpoint

  talos_version      = "v1.7.6"
  kubernetes_version = "v1.30.3"
}

module "nuremberg" {
  count  = length(module.pools_nuremberg)
  source = "github.com/miran248/terraform-talos-modules//modules/hcloud"

  layout = module.layout
  zone   = module.zones_nuremberg[count.index]
  pool   = module.pools_nuremberg[count.index]
  config = module.talos_config

  datacenter = data.hcloud_datacenter.nuremberg
  location   = data.hcloud_location.nuremberg
  image_id   = data.hcloud_image.v1_7_6_amd64.id

  router = local.hcloud_router
  # router_client = local.hcloud_router_client

  depends_on = [
    module.talos_config,
    module.pools_nuremberg,
  ]
}
module "falkenstein" {
  count  = length(module.pools_falkenstein)
  source = "github.com/miran248/terraform-talos-modules//modules/hcloud"

  layout = module.layout
  zone   = module.zones_falkenstein[count.index]
  pool   = module.pools_falkenstein[count.index]
  config = module.talos_config

  datacenter = data.hcloud_datacenter.falkenstein
  location   = data.hcloud_location.falkenstein
  image_id   = data.hcloud_image.v1_7_6_amd64.id

  router = local.hcloud_router
  # router_client = local.hcloud_router_client

  depends_on = [
    module.talos_config,
    module.pools_falkenstein,
  ]
}

# adds dns entry for first load balancer
resource "google_dns_record_set" "talos_ipv4" {
  name         = "k.${google_dns_managed_zone.this.dns_name}"
  managed_zone = google_dns_managed_zone.this.name
  type         = "A"
  ttl          = 300
  project      = google_project.this.project_id

  rrdatas = [
    module.nuremberg[0].ips4.load_balancer,
  ]

  depends_on = [
    module.nuremberg,
  ]
}

module "talos_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-apply"

  config = module.talos_config

  depends_on = [
    module.nuremberg,
    module.falkenstein,
  ]
}

# provider "kubernetes" {
#   host                   = local.endpoint
#   client_certificate     = module.talos_apply.client_certificate
#   client_key             = module.talos_apply.client_key
#   cluster_ca_certificate = module.talos_apply.cluster_ca_certificate
# }
