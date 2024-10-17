data "hcloud_image" "dev46_v1_8_1_amd64" {
  with_selector = "name=talos,version=v1.8.1,arch=amd64"
}

data "hcloud_datacenter" "dev46_nuremberg" {
  name = "nbg1-dc3"
}
data "hcloud_location" "dev46_nuremberg" {
  name = "nbg1"
}
data "hcloud_datacenter" "dev46_helsinki" {
  name = "hel1-dc2"
}
data "hcloud_location" "dev46_helsinki" {
  name = "hel1"
}

locals {
  dev46_patches_zitadel = <<-EOF
    machine:
      nodeLabels:
        app: zitadel
  EOF
}

module "dev46_talos_cluster" {
  source = "../modules/talos-cluster"

  name     = "dev46"
  endpoint = "dev46.dev.248.sh"

  features = {
    ip6 = true
  }

  patches = {
    common = [
      yamlencode({
        cluster = {
          extraManifests = [
            "https://raw.githubusercontent.com/miran248/terraform-talos-modules/95c41f61ca0801479fd713d6c26810b8bdfcbb9d/manifests/hcloud-csi.yaml",
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
        machine = {
          network = {
            nameservers = [
              "2a00:1098:2b::1",      # https://nat64.net
              "2a00:1098:2c::1",      # https://nat64.net
              "2a01:4f8:c2c:123f::1", # https://nat64.net
            ]
          }
          time = {
            servers = [
              "/dev/ptp0",
            ]
          }
        }
      }),
    ]
  }
}

module "dev46_nuremberg_pool_1" {
  source = "../modules/node-pool"

  cluster = module.dev46_talos_cluster

  zone = 1

  nodes = {
    control_planes = [
      { server_type = "cx22" },
      { server_type = "cx22" },
      { server_type = "cx22" },
    ]
    workers = [
      { server_type = "cx22", patches = [local.dev46_patches_zitadel] },
      { server_type = "cx22", patches = [local.dev46_patches_zitadel] },
      # { server_type = "cx22", patches = [local.dev46_patches_zitadel] },
    ]
  }
}
module "dev46_helsinki_pool_1" {
  source = "../modules/node-pool"

  cluster = module.dev46_talos_cluster

  zone = 2

  nodes = {
    workers = [
      { server_type = "cx22" },
    ]
  }
}

module "dev46_nuremberg_network_1" {
  source = "../modules/hcloud-network"

  datacenter = data.hcloud_datacenter.dev46_nuremberg
  location   = data.hcloud_location.dev46_nuremberg

  cluster = module.dev46_talos_cluster
  pool    = module.dev46_nuremberg_pool_1
}
module "dev46_helsinki_network_1" {
  source = "../modules/hcloud-network"

  datacenter = data.hcloud_datacenter.dev46_helsinki
  location   = data.hcloud_location.dev46_helsinki

  cluster = module.dev46_talos_cluster
  pool    = module.dev46_helsinki_pool_1
}

module "dev46_talos_config" {
  source = "../modules/talos-config"

  cluster = module.dev46_talos_cluster
  networks = [
    module.dev46_nuremberg_network_1,
    module.dev46_helsinki_network_1,
  ]

  talos_version      = "v1.8.1"
  kubernetes_version = "v1.31.1"
}

module "dev46_nuremberg_1" {
  source = "../modules/hcloud-servers"

  datacenter = data.hcloud_datacenter.dev46_nuremberg
  location   = data.hcloud_location.dev46_nuremberg
  image_id   = data.hcloud_image.dev46_v1_8_1_amd64.id

  cluster = module.dev46_talos_cluster
  pool    = module.dev46_nuremberg_pool_1
  network = module.dev46_nuremberg_network_1
  config  = module.dev46_talos_config

  depends_on = [
    module.dev46_nuremberg_network_1,
    module.dev46_talos_config,
  ]
}
module "dev46_helsinki_1" {
  source = "../modules/hcloud-servers"

  datacenter = data.hcloud_datacenter.dev46_helsinki
  location   = data.hcloud_location.dev46_helsinki
  image_id   = data.hcloud_image.dev46_v1_8_1_amd64.id

  cluster = module.dev46_talos_cluster
  pool    = module.dev46_helsinki_pool_1
  network = module.dev46_helsinki_network_1
  config  = module.dev46_talos_config

  depends_on = [
    module.dev46_helsinki_network_1,
    module.dev46_talos_config,
  ]
}

locals {
  dev46_node_cidrs6 = [for key, node in module.dev46_talos_config.nodes : node.public_ip6_network_64]
}

resource "hcloud_firewall" "dev46" {
  name = "dev46-internal-traffic"

  dynamic "rule" {
    for_each = toset(["tcp", "udp"])
    content {
      direction       = "in"
      protocol        = rule.value
      port            = "any"
      source_ips      = local.dev46_node_cidrs6
      destination_ips = local.dev46_node_cidrs6
    }
  }
  dynamic "rule" {
    for_each = toset(["icmp", "gre", "esp"])
    content {
      direction       = "in"
      protocol        = rule.value
      source_ips      = local.dev46_node_cidrs6
      destination_ips = local.dev46_node_cidrs6
    }
  }
}
resource "hcloud_firewall_attachment" "dev46" {
  firewall_id = hcloud_firewall.dev46.id
  server_ids = flatten([
    values(module.dev46_nuremberg_1.ids),
    values(module.dev46_helsinki_1.ids),
  ])
}


resource "google_dns_record_set" "dev46_talos_ipv6" {
  name         = "${module.dev46_talos_cluster.name}.${data.google_dns_managed_zone.this.dns_name}"
  managed_zone = data.google_dns_managed_zone.this.name
  type         = "AAAA"
  ttl          = 300

  rrdatas = module.dev46_talos_config.public_ips6.control_planes

  depends_on = [
    module.dev46_nuremberg_network_1,
  ]
}

module "dev46_talos_apply" {
  source = "../modules/talos-apply"

  cluster = module.dev46_talos_cluster
  config  = module.dev46_talos_config

  depends_on = [
    module.dev46_nuremberg_1,
    module.dev46_helsinki_1,
  ]
}

# outputs
output "dev46_talos_config" {
  value     = module.dev46_talos_config.talos_config
  sensitive = true
}
