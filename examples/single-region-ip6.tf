data "hcloud_image" "single6_v1_8_1_amd64" {
  with_selector = "name=talos,version=v1.8.1,arch=amd64"
}

data "hcloud_datacenter" "single6_nuremberg" {
  name = "nbg1-dc3"
}
data "hcloud_location" "single6_nuremberg" {
  name = "nbg1"
}
# data "hcloud_datacenter" "single6_helsinki" {
#   name = "hel1-dc2"
# }
# data "hcloud_location" "single6_helsinki" {
#   name = "hel1"
# }

locals {
  single6_patches_zitadel = <<-EOF
    machine:
      nodeLabels:
        app: zitadel
  EOF
}

module "single6_talos_cluster" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-cluster?ref=v1.3.0"

  name     = "single6"
  endpoint = "single6.example.com"

  features = {
    ip6 = true
  }

  patches = {
    common = [
      yamlencode({
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

module "single6_nuremberg_pool_1" {
  source = "github.com/miran248/terraform-talos-modules//modules/node-pool?ref=v1.3.0"

  cluster = module.single6_talos_cluster

  zone = 1

  nodes = {
    control_planes = [
      # mark node as `removed` instead of deleting it, otherwise it will shift and recreate all subsequent nodes!
      # can be useful in case it receives a blacklisted ip
      { removed = true, server_type = "cx22" },
      { server_type = "cx22" },
      { server_type = "cx22" },
      { server_type = "cx22" },
    ]
    workers = [
      { server_type = "cx22", patches = [local.single6_patches_zitadel] },
      { server_type = "cx22", patches = [local.single6_patches_zitadel] },
      # { server_type = "cx22", patches = [local.single6_patches_zitadel] },
    ]
  }
}
# module "single6_helsinki_pool_1" {
#   source = "github.com/miran248/terraform-talos-modules//modules/node-pool?ref=v1.3.0"

#   cluster = module.single6_talos_cluster

#   zone = 2

#   nodes = {
#     workers = [
#       { server_type = "cx22" },
#     ]
#   }
# }

module "single6_nuremberg_network_1" {
  source = "github.com/miran248/terraform-talos-modules//modules/hcloud-network?ref=v1.3.0"

  datacenter = data.hcloud_datacenter.single6_nuremberg
  location   = data.hcloud_location.single6_nuremberg

  cluster = module.single6_talos_cluster
  pool    = module.single6_nuremberg_pool_1
}
# module "single6_helsinki_network_1" {
#   source = "github.com/miran248/terraform-talos-modules//modules/hcloud-network?ref=v1.3.0"

#   datacenter = data.hcloud_datacenter.single6_helsinki
#   location   = data.hcloud_location.single6_helsinki

#   cluster = module.single6_talos_cluster
#   pool    = module.single6_helsinki_pool_1
# }

module "single6_talos_config" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-config?ref=v1.3.0"

  cluster = module.single6_talos_cluster
  networks = [
    module.single6_nuremberg_network_1,
    # module.single6_helsinki_network_1,
  ]

  talos_version      = "v1.8.1"
  kubernetes_version = "v1.31.1"
}

module "single6_nuremberg_1" {
  source = "github.com/miran248/terraform-talos-modules//modules/hcloud-servers?ref=v1.3.0"

  datacenter = data.hcloud_datacenter.single6_nuremberg
  location   = data.hcloud_location.single6_nuremberg
  image_id   = data.hcloud_image.single6_v1_8_1_amd64.id

  cluster = module.single6_talos_cluster
  pool    = module.single6_nuremberg_pool_1
  network = module.single6_nuremberg_network_1
  config  = module.single6_talos_config

  depends_on = [
    module.single6_nuremberg_network_1,
    module.single6_talos_config,
  ]
}
# module "single6_helsinki_1" {
#   source = "github.com/miran248/terraform-talos-modules//modules/hcloud-servers?ref=v1.3.0"

#   datacenter = data.hcloud_datacenter.single6_helsinki
#   location   = data.hcloud_location.single6_helsinki
#   image_id   = data.hcloud_image.single6_v1_8_1_amd64.id

#   cluster = module.single6_talos_cluster
#   pool    = module.single6_helsinki_pool_1
#   network = module.single6_helsinki_network_1
#   config  = module.single6_talos_config

#   depends_on = [
#     module.single6_helsinki_network_1,
#     module.single6_talos_config,
#   ]
# }

resource "google_dns_record_set" "single6_talos_ipv6" {
  name         = "${module.single6_talos_cluster.name}.${google_dns_managed_zone.this.dns_name}"
  managed_zone = google_dns_managed_zone.this.name
  type         = "AAAA"
  ttl          = 300
  project      = google_project.this.project_id

  rrdatas = module.single6_talos_config.public_ips6.control_planes

  depends_on = [
    module.single6_nuremberg_network_1,
  ]
}
# resource "google_dns_record_set" "single6_talos_ipv4" {
#   name         = "${module.single6_talos_cluster.name}.${google_dns_managed_zone.this.dns_name}"
#   managed_zone = google_dns_managed_zone.this.name
#   type         = "A"
#   ttl          = 300
#   project      = google_project.this.project_id

#   rrdatas = module.single6_talos_config.public_ips4.control_planes

#   depends_on = [
#     module.single6_nuremberg_network_1,
#   ]
# }

module "single6_talos_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-apply?ref=v1.3.0"

  cluster = module.single6_talos_cluster
  config  = module.single6_talos_config

  depends_on = [
    module.single6_nuremberg_1,
    # module.single6_helsinki_1,
  ]
}

# outputs
output "single6_talos_config" {
  value     = module.single6_talos_config.talos_config
  sensitive = true
}
