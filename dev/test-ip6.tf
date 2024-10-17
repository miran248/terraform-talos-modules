data "hcloud_image" "dev66_v1_8_1_amd64" {
  with_selector = "name=talos,version=v1.8.1,arch=amd64"
}

data "hcloud_datacenter" "dev66_nuremberg" {
  name = "nbg1-dc3"
}
data "hcloud_location" "dev66_nuremberg" {
  name = "nbg1"
}
# data "hcloud_datacenter" "dev66_helsinki" {
#   name = "hel1-dc2"
# }
# data "hcloud_location" "dev66_helsinki" {
#   name = "hel1"
# }

locals {
  dev66_patches_zitadel = <<-EOF
    machine:
      nodeLabels:
        app: zitadel
  EOF
}

module "dev66_talos_cluster" {
  source = "../modules/talos-cluster"

  name     = "dev66"
  endpoint = "dev66.dev.248.sh"

  features = {
    ip6 = true
  }

  patches = {
    common = [
      yamlencode({
        cluster = {
          # extraManifests = [
          #   "https://raw.githubusercontent.com/miran248/terraform-talos-modules/95c41f61ca0801479fd713d6c26810b8bdfcbb9d/manifests/hcloud-csi.yaml",
          # ]
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

module "dev66_nuremberg_pool_1" {
  source = "../modules/node-pool"

  cluster = module.dev66_talos_cluster

  zone = 1

  nodes = {
    control_planes = [
      { server_type = "cx22" },
      # { server_type = "cx22" },
      # { server_type = "cx22" },
    ]
    workers = [
      { server_type = "cx22", patches = [local.dev66_patches_zitadel] },
      # { server_type = "cx22", patches = [local.dev66_patches_zitadel] },
      # { server_type = "cx22", patches = [local.dev66_patches_zitadel] },
    ]
  }
}
# module "dev66_helsinki_pool_1" {
#   source = "../modules/node-pool"

#   cluster = module.dev66_talos_cluster

#   zone = 2

#   nodes = {
#     workers = [
#       { server_type = "cx22" },
#     ]
#   }
# }

module "dev66_nuremberg_network_1" {
  source = "../modules/hcloud-network"

  datacenter = data.hcloud_datacenter.dev66_nuremberg
  location   = data.hcloud_location.dev66_nuremberg

  cluster = module.dev66_talos_cluster
  pool    = module.dev66_nuremberg_pool_1
}
# module "dev66_helsinki_network_1" {
#   source = "../modules/hcloud-network"

#   datacenter = data.hcloud_datacenter.dev66_helsinki
#   location   = data.hcloud_location.dev66_helsinki

#   cluster = module.dev66_talos_cluster
#   pool    = module.dev66_helsinki_pool_1
# }

module "dev66_talos_config" {
  source = "../modules/talos-config"

  cluster = module.dev66_talos_cluster
  networks = [
    module.dev66_nuremberg_network_1,
    # module.dev66_helsinki_network_1,
  ]

  talos_version      = "v1.8.1"
  kubernetes_version = "v1.31.1"
}

module "dev66_nuremberg_1" {
  source = "../modules/hcloud-servers"

  datacenter = data.hcloud_datacenter.dev66_nuremberg
  location   = data.hcloud_location.dev66_nuremberg
  image_id   = data.hcloud_image.dev66_v1_8_1_amd64.id

  cluster = module.dev66_talos_cluster
  pool    = module.dev66_nuremberg_pool_1
  network = module.dev66_nuremberg_network_1
  config  = module.dev66_talos_config

  depends_on = [
    module.dev66_nuremberg_network_1,
    module.dev66_talos_config,
  ]
}
# module "dev66_helsinki_1" {
#   source = "../modules/hcloud-servers"

#   datacenter = data.hcloud_datacenter.dev66_helsinki
#   location   = data.hcloud_location.dev66_helsinki
#   image_id   = data.hcloud_image.dev66_v1_8_1_amd64.id

#   cluster = module.dev66_talos_cluster
#   pool    = module.dev66_helsinki_pool_1
#   network = module.dev66_helsinki_network_1
#   config  = module.dev66_talos_config

#   depends_on = [
#     module.dev66_helsinki_network_1,
#     module.dev66_talos_config,
#   ]
# }

locals {
  dev66_node_cidrs6 = [for key, node in module.dev66_talos_config.nodes : node.public_ip6_network_64]
}

resource "hcloud_firewall" "dev66" {
  name = "dev66-internal-traffic"

  dynamic "rule" {
    for_each = toset(["tcp", "udp"])
    content {
      direction       = "in"
      protocol        = rule.value
      port            = "any"
      source_ips      = local.dev66_node_cidrs6
      destination_ips = local.dev66_node_cidrs6
    }
  }
  dynamic "rule" {
    for_each = toset(["icmp", "gre", "esp"])
    content {
      direction       = "in"
      protocol        = rule.value
      source_ips      = local.dev66_node_cidrs6
      destination_ips = local.dev66_node_cidrs6
    }
  }
}
resource "hcloud_firewall_attachment" "dev66" {
  firewall_id = hcloud_firewall.dev66.id
  server_ids = flatten([
    values(module.dev66_nuremberg_1.ids),
    # values(module.dev66_helsinki_1.ids),
  ])
}


resource "google_dns_record_set" "dev66_talos_ipv6" {
  name         = "${module.dev66_talos_cluster.name}.${data.google_dns_managed_zone.this.dns_name}"
  managed_zone = data.google_dns_managed_zone.this.name
  type         = "AAAA"
  ttl          = 300

  rrdatas = module.dev66_talos_config.public_ips6.control_planes

  depends_on = [
    module.dev66_nuremberg_network_1,
  ]
}

module "dev66_talos_apply" {
  source = "../modules/talos-apply"

  cluster = module.dev66_talos_cluster
  config  = module.dev66_talos_config

  depends_on = [
    module.dev66_nuremberg_1,
    # module.dev66_helsinki_1,
  ]
}

# outputs
output "dev66_talos_config" {
  value     = module.dev66_talos_config.talos_config
  sensitive = true
}
