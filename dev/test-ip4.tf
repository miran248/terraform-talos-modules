# data "hcloud_image" "dev14_v1_8_1_amd64" {
#   with_selector = "name=talos,version=v1.8.1,arch=amd64"
# }

# data "hcloud_datacenter" "dev14_nuremberg" {
#   name = "nbg1-dc3"
# }
# data "hcloud_location" "dev14_nuremberg" {
#   name = "nbg1"
# }
# # data "hcloud_datacenter" "dev14_helsinki" {
# #   name = "hel1-dc2"
# # }
# # data "hcloud_location" "dev14_helsinki" {
# #   name = "hel1"
# # }

# locals {
#   dev14_patches_zitadel = <<-EOF
#     machine:
#       nodeLabels:
#         app: zitadel
#   EOF
# }

# module "dev14_talos_cluster" {
#   source = "../modules/talos-cluster"

#   name     = "dev14"
#   endpoint = "dev14.dev.248.sh"

#   features = {
#     ip4 = true
#   }

#   patches = {
#     common = [
#       yamlencode({
#         cluster = {
#           extraManifests = [
#             "https://raw.githubusercontent.com/miran248/terraform-talos-modules/refs/tags/v1.3.0/manifests/hcloud-csi.yaml",
#           ]
#           inlineManifests = [
#             {
#               name     = "hcloud-secret",
#               contents = <<-EOF
#                 apiVersion: v1
#                 kind: Secret
#                 metadata:
#                   name: hcloud
#                   namespace: kube-system
#                 stringData:
#                   token: ${var.hcloud_token}
#                 type: Opaque
#               EOF
#             },
#           ]
#         }
#         machine = {
#           time = {
#             servers = [
#               "/dev/ptp0",
#             ]
#           }
#         }
#       }),
#     ]
#   }
# }

# module "dev14_nuremberg_pool_1" {
#   source = "../modules/node-pool"

#   cluster = module.dev14_talos_cluster

#   zone = 1

#   nodes = {
#     control_planes = [
#       { server_type = "cx22" },
#       { server_type = "cx22" },
#       { server_type = "cx22" },
#     ]
#     workers = [
#       { server_type = "cx22", patches = [local.dev14_patches_zitadel] },
#       { server_type = "cx22", patches = [local.dev14_patches_zitadel] },
#       # { server_type = "cx22", patches = [local.dev14_patches_zitadel] },
#     ]
#   }
# }
# # module "dev14_helsinki_pool_1" {
# #   source = "../modules/node-pool"

# #   cluster = module.dev14_talos_cluster

# #   zone = 2

# #   nodes = {
# #     control_planes = [
# #       { server_type = "cx22" },
# #     ]
# #     workers = [
# #       { server_type = "cx22" },
# #     ]
# #   }
# # }

# module "dev14_nuremberg_network_1" {
#   source = "../modules/hcloud-network"

#   datacenter = data.hcloud_datacenter.dev14_nuremberg
#   location   = data.hcloud_location.dev14_nuremberg

#   cluster = module.dev14_talos_cluster
#   pool    = module.dev14_nuremberg_pool_1
# }
# # module "dev14_helsinki_network_1" {
# #   source = "../modules/hcloud-network"

# #   datacenter = data.hcloud_datacenter.dev14_helsinki
# #   location   = data.hcloud_location.dev14_helsinki

# #   cluster = module.dev14_talos_cluster
# #   pool    = module.dev14_helsinki_pool_1
# # }

# module "dev14_talos_config" {
#   source = "../modules/talos-config"

#   cluster = module.dev14_talos_cluster
#   networks = [
#     module.dev14_nuremberg_network_1,
#     # module.dev14_helsinki_network_1,
#   ]

#   talos_version      = "v1.8.1"
#   kubernetes_version = "v1.31.1"
# }

# module "dev14_nuremberg_1" {
#   source = "../modules/hcloud-servers"

#   datacenter = data.hcloud_datacenter.dev14_nuremberg
#   location   = data.hcloud_location.dev14_nuremberg
#   image_id   = data.hcloud_image.dev14_v1_8_1_amd64.id

#   cluster = module.dev14_talos_cluster
#   pool    = module.dev14_nuremberg_pool_1
#   network = module.dev14_nuremberg_network_1
#   config  = module.dev14_talos_config

#   depends_on = [
#     module.dev14_nuremberg_network_1,
#     module.dev14_talos_config,
#   ]
# }
# # module "dev14_helsinki_1" {
# #   source = "../modules/hcloud-servers"

# #   datacenter = data.hcloud_datacenter.dev14_helsinki
# #   location   = data.hcloud_location.dev14_helsinki
# #   image_id   = data.hcloud_image.dev14_v1_8_1_amd64.id

# #   cluster = module.dev14_talos_cluster
# #   pool    = module.dev14_helsinki_pool_1
# #   network = module.dev14_helsinki_network_1
# #   config  = module.dev14_talos_config

# #   depends_on = [
# #     module.dev14_helsinki_network_1,
# #     module.dev14_talos_config,
# #   ]
# # }

# resource "google_dns_record_set" "dev14_talos_ipv4" {
#   name         = "${module.dev14_talos_cluster.name}.${data.google_dns_managed_zone.this.dns_name}"
#   managed_zone = data.google_dns_managed_zone.this.name
#   type         = "A"
#   ttl          = 300

#   rrdatas = module.dev14_talos_config.public_ips4.control_planes

#   depends_on = [
#     module.dev14_nuremberg_network_1,
#   ]
# }

# module "dev14_talos_apply" {
#   source = "../modules/talos-apply"

#   cluster = module.dev14_talos_cluster
#   config  = module.dev14_talos_config

#   depends_on = [
#     module.dev14_nuremberg_1,
#     # module.dev14_helsinki_1,
#   ]
# }

# # outputs
# output "dev14_talos_config" {
#   value     = module.dev14_talos_config.talos_config
#   sensitive = true
# }
