data "hcloud_image" "dev26_v1_8_1_amd64" {
  with_selector = "name=talos,version=v1.8.1,arch=amd64"
}

data "hcloud_datacenter" "dev26_nuremberg" {
  name = "nbg1-dc3"
}
data "hcloud_location" "dev26_nuremberg" {
  name = "nbg1"
}
# data "hcloud_datacenter" "dev26_helsinki" {
#   name = "hel1-dc2"
# }
# data "hcloud_location" "dev26_helsinki" {
#   name = "hel1"
# }

locals {
  dev26_patches_zitadel = <<-EOF
    machine:
      nodeLabels:
        app: zitadel
  EOF
}

module "dev26_talos_cluster" {
  source = "../modules/talos-cluster"

  name     = "dev26"
  endpoint = "dev26.dev.248.sh"

  features = {
    ip6 = true
  }

  patches = {
    common = [
      yamlencode({
        cluster = {
          extraManifests = [
            "https://raw.githubusercontent.com/miran248/terraform-talos-modules/refs/tags/v1.1.0/manifests/hcloud-csi.yaml",
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

module "dev26_nuremberg_pool_1" {
  source = "../modules/node-pool"

  cluster = module.dev26_talos_cluster

  zone = 1

  nodes = {
    control_planes = [
      { server_type = "cx22" },
      { server_type = "cx22" },
      { server_type = "cx22" },
    ]
    workers = [
      { server_type = "cx22", patches = [local.dev26_patches_zitadel] },
      { server_type = "cx22", patches = [local.dev26_patches_zitadel] },
      # { server_type = "cx22", patches = [local.dev26_patches_zitadel] },
    ]
  }
}
# module "dev26_helsinki_pool_1" {
#   source = "../modules/node-pool"

#   cluster = module.dev26_talos_cluster

#   zone = 2

#   nodes = {
#     control_planes = [
#       { server_type = "cx22" },
#     ]
#     workers = [
#       { server_type = "cx22" },
#     ]
#   }
# }

module "dev26_nuremberg_network_1" {
  source = "../modules/hcloud-network"

  datacenter = data.hcloud_datacenter.dev26_nuremberg
  location   = data.hcloud_location.dev26_nuremberg

  cluster = module.dev26_talos_cluster
  pool    = module.dev26_nuremberg_pool_1
}
# module "dev26_helsinki_network_1" {
#   source = "../modules/hcloud-network"

#   datacenter = data.hcloud_datacenter.dev26_helsinki
#   location   = data.hcloud_location.dev26_helsinki

#   cluster = module.dev26_talos_cluster
#   pool    = module.dev26_helsinki_pool_1
# }

module "dev26_talos_config" {
  source = "../modules/talos-config"

  cluster = module.dev26_talos_cluster
  networks = [
    module.dev26_nuremberg_network_1,
    # module.dev26_helsinki_network_1,
  ]

  talos_version      = "v1.8.1"
  kubernetes_version = "v1.31.1"
}

module "dev26_nuremberg_1" {
  source = "../modules/hcloud-servers"

  datacenter = data.hcloud_datacenter.dev26_nuremberg
  location   = data.hcloud_location.dev26_nuremberg
  image_id   = data.hcloud_image.dev26_v1_8_1_amd64.id

  cluster = module.dev26_talos_cluster
  pool    = module.dev26_nuremberg_pool_1
  network = module.dev26_nuremberg_network_1
  config  = module.dev26_talos_config

  depends_on = [
    module.dev26_nuremberg_network_1,
    module.dev26_talos_config,
  ]
}
# module "dev26_helsinki_1" {
#   source = "../modules/hcloud-servers"

#   datacenter = data.hcloud_datacenter.dev26_helsinki
#   location   = data.hcloud_location.dev26_helsinki
#   image_id   = data.hcloud_image.dev26_v1_8_1_amd64.id

#   cluster = module.dev26_talos_cluster
#   pool    = module.dev26_helsinki_pool_1
#   network = module.dev26_helsinki_network_1
#   config  = module.dev26_talos_config

#   depends_on = [
#     module.dev26_helsinki_network_1,
#     module.dev26_talos_config,
#   ]
# }

resource "google_dns_record_set" "dev26_talos_ipv6" {
  name         = "${module.dev26_talos_cluster.name}.${data.google_dns_managed_zone.this.dns_name}"
  managed_zone = data.google_dns_managed_zone.this.name
  type         = "AAAA"
  ttl          = 300

  rrdatas = module.dev26_talos_config.public_ips6.control_planes

  depends_on = [
    module.dev26_nuremberg_network_1,
  ]
}

module "dev26_talos_apply" {
  source = "../modules/talos-apply"

  cluster = module.dev26_talos_cluster
  config  = module.dev26_talos_config

  depends_on = [
    module.dev26_nuremberg_1,
    # module.dev26_helsinki_1,
  ]
}

# outputs
output "dev26_talos_config" {
  value     = module.dev26_talos_config.talos_config
  sensitive = true
}
