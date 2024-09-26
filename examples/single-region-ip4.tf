data "hcloud_image" "single4_v1_8_0_amd64" {
  with_selector = "name=talos,version=v1.8.0,arch=amd64"
}

data "hcloud_datacenter" "single4_nuremberg" {
  name = "nbg1-dc3"
}
data "hcloud_location" "single4_nuremberg" {
  name = "nbg1"
}
# data "hcloud_datacenter" "single4_helsinki" {
#   name = "hel1-dc2"
# }
# data "hcloud_location" "single4_helsinki" {
#   name = "hel1"
# }

locals {
  single4_patches_zitadel = <<-EOF
    machine:
      nodeLabels:
        app: zitadel
  EOF
}

module "single4_talos_cluster" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-cluster?ref=v1.0.0"

  name     = "single4"
  endpoint = "single4.example.com"

  features = {
    ip4 = true
  }

  patches = {
    common = [
      yamlencode({
        machine = {
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

module "single4_nuremberg_pool_1" {
  source = "github.com/miran248/terraform-talos-modules//modules/node-pool?ref=v1.0.0"

  cluster = module.single4_talos_cluster

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
      { server_type = "cx22", patches = [local.single4_patches_zitadel] },
      { server_type = "cx22", patches = [local.single4_patches_zitadel] },
      # { server_type = "cx22", patches = [local.single4_patches_zitadel] },
    ]
  }
}
# module "single4_helsinki_pool_1" {
#   source = "github.com/miran248/terraform-talos-modules//modules/node-pool?ref=v1.0.0"

#   cluster = module.single4_talos_cluster

#   zone = 2

#   nodes = {
#     workers = [
#       { server_type = "cx22" },
#     ]
#   }
# }

module "single4_nuremberg_network_1" {
  source = "github.com/miran248/terraform-talos-modules//modules/hcloud-network?ref=v1.0.0"

  datacenter = data.hcloud_datacenter.single4_nuremberg
  location   = data.hcloud_location.single4_nuremberg

  cluster = module.single4_talos_cluster
  pool    = module.single4_nuremberg_pool_1
}
# module "single4_helsinki_network_1" {
#   source = "github.com/miran248/terraform-talos-modules//modules/hcloud-network?ref=v1.0.0"

#   datacenter = data.hcloud_datacenter.single4_helsinki
#   location   = data.hcloud_location.single4_helsinki

#   cluster = module.single4_talos_cluster
#   pool    = module.single4_helsinki_pool_1
# }

module "single4_talos_config" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-config?ref=v1.0.0"

  cluster = module.single4_talos_cluster
  networks = [
    module.single4_nuremberg_network_1,
    # module.single4_helsinki_network_1,
  ]

  talos_version      = "v1.8.0"
  kubernetes_version = "v1.31.1"
}

module "single4_nuremberg_1" {
  source = "github.com/miran248/terraform-talos-modules//modules/hcloud-servers?ref=v1.0.0"

  datacenter = data.hcloud_datacenter.single4_nuremberg
  location   = data.hcloud_location.single4_nuremberg
  image_id   = data.hcloud_image.single4_v1_8_0_amd64.id

  cluster = module.single4_talos_cluster
  pool    = module.single4_nuremberg_pool_1
  network = module.single4_nuremberg_network_1
  config  = module.single4_talos_config

  depends_on = [
    module.single4_nuremberg_network_1,
    module.single4_talos_config,
  ]
}
# module "single4_helsinki_1" {
#   source = "github.com/miran248/terraform-talos-modules//modules/hcloud-servers?ref=v1.0.0"

#   datacenter = data.hcloud_datacenter.single4_helsinki
#   location   = data.hcloud_location.single4_helsinki
#   image_id   = data.hcloud_image.single4_v1_8_0_amd64.id

#   cluster = module.single4_talos_cluster
#   pool    = module.single4_helsinki_pool_1
#   network = module.single4_helsinki_network_1
#   config  = module.single4_talos_config

#   depends_on = [
#     module.single4_helsinki_network_1,
#     module.single4_talos_config,
#   ]
# }

# resource "google_dns_record_set" "single4_talos_ipv6" {
#   name         = "${module.single4_talos_cluster.name}.${google_dns_managed_zone.this.dns_name}"
#   managed_zone = google_dns_managed_zone.this.name
#   type         = "AAAA"
#   ttl          = 300
#   project      = google_project.this.project_id

#   rrdatas = module.single4_talos_config.public_ips6.control_planes

#   depends_on = [
#     module.single4_nuremberg_network_1,
#   ]
# }
resource "google_dns_record_set" "single4_talos_ipv4" {
  name         = "${module.single4_talos_cluster.name}.${google_dns_managed_zone.this.dns_name}"
  managed_zone = google_dns_managed_zone.this.name
  type         = "A"
  ttl          = 300
  project      = google_project.this.project_id

  rrdatas = module.single4_talos_config.public_ips4.control_planes

  depends_on = [
    module.single4_nuremberg_network_1,
  ]
}

module "single4_talos_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-apply?ref=v1.0.0"

  cluster = module.single4_talos_cluster
  config  = module.single4_talos_config

  depends_on = [
    module.single4_nuremberg_1,
    # module.single4_helsinki_1,
  ]
}

# outputs
output "single4_talos_config" {
  value     = module.single4_talos_config.talos_config
  sensitive = true
}
