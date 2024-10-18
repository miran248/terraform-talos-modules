data "hcloud_image" "dev3_v1_8_1_amd64" {
  with_selector = "name=talos,version=v1.8.1,arch=amd64"
}

data "hcloud_datacenter" "dev3_nuremberg" {
  name = "nbg1-dc3"
}
data "hcloud_location" "dev3_nuremberg" {
  name = "nbg1"
}
# data "hcloud_datacenter" "dev3_helsinki" {
#   name = "hel1-dc2"
# }
# data "hcloud_location" "dev3_helsinki" {
#   name = "hel1"
# }

locals {
  dev3_patches_zitadel = <<-EOF
    machine:
      nodeLabels:
        app: zitadel
  EOF
}

module "dev3_talos_cluster" {
  source = "../modules/talos-cluster"

  name     = "dev3"
  endpoint = "dev3.dev.248.sh"

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

module "dev3_nuremberg_pool_1" {
  source = "../modules/node-pool"

  cluster = module.dev3_talos_cluster

  zone = 1

  nodes = {
    control_planes = [
      { server_type = "cx22" },
      # { server_type = "cx22" },
      # { server_type = "cx22" },
    ]
    workers = [
      { server_type = "cx22", patches = [local.dev3_patches_zitadel] },
      # { server_type = "cx22", patches = [local.dev3_patches_zitadel] },
      # { server_type = "cx22", patches = [local.dev3_patches_zitadel] },
    ]
  }
}
# module "dev3_helsinki_pool_1" {
#   source = "../modules/node-pool"

#   cluster = module.dev3_talos_cluster

#   zone = 2

#   nodes = {
#     workers = [
#       { server_type = "cx22" },
#     ]
#   }
# }

module "dev3_nuremberg_network_1" {
  source = "../modules/hcloud-network"

  datacenter = data.hcloud_datacenter.dev3_nuremberg
  location   = data.hcloud_location.dev3_nuremberg

  pool = module.dev3_nuremberg_pool_1
}
# module "dev3_helsinki_network_1" {
#   source = "../modules/hcloud-network"

#   datacenter = data.hcloud_datacenter.dev3_helsinki
#   location   = data.hcloud_location.dev3_helsinki

#   pool    = module.dev3_helsinki_pool_1
# }

module "dev3_talos_config" {
  source = "../modules/talos-config"

  cluster = module.dev3_talos_cluster
  networks = [
    module.dev3_nuremberg_network_1,
    # module.dev3_helsinki_network_1,
  ]

  talos_version      = "v1.8.1"
  kubernetes_version = "v1.31.1"
}

module "dev3_nuremberg_1" {
  source = "../modules/hcloud-servers"

  datacenter = data.hcloud_datacenter.dev3_nuremberg
  location   = data.hcloud_location.dev3_nuremberg
  image_id   = data.hcloud_image.dev3_v1_8_1_amd64.id

  pool    = module.dev3_nuremberg_pool_1
  network = module.dev3_nuremberg_network_1
  config  = module.dev3_talos_config

  depends_on = [
    module.dev3_nuremberg_network_1,
    module.dev3_talos_config,
  ]
}
# module "dev3_helsinki_1" {
#   source = "../modules/hcloud-servers"

#   datacenter = data.hcloud_datacenter.dev3_helsinki
#   location   = data.hcloud_location.dev3_helsinki
#   image_id   = data.hcloud_image.dev3_v1_8_1_amd64.id

#   pool    = module.dev3_helsinki_pool_1
#   network = module.dev3_helsinki_network_1
#   config  = module.dev3_talos_config

#   depends_on = [
#     module.dev3_helsinki_network_1,
#     module.dev3_talos_config,
#   ]
# }

resource "google_dns_record_set" "dev3_talos_ipv6" {
  name         = "${module.dev3_talos_cluster.name}.${data.google_dns_managed_zone.this.dns_name}"
  managed_zone = data.google_dns_managed_zone.this.name
  type         = "AAAA"
  ttl          = 300

  rrdatas = module.dev3_talos_config.public_ips6.control_planes

  depends_on = [
    module.dev3_nuremberg_network_1,
  ]
}

module "dev3_talos_apply" {
  source = "../modules/talos-apply"

  cluster = module.dev3_talos_cluster
  config  = module.dev3_talos_config

  depends_on = [
    module.dev3_nuremberg_1,
    # module.dev3_helsinki_1,
  ]
}

# outputs
output "dev3_talos_config" {
  value     = module.dev3_talos_config.talos_config
  sensitive = true
}
