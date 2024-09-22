# data "hcloud_image" "nbg14_v1_7_6_amd64" {
#   with_selector = "name=talos,version=v1.7.6,arch=amd64"
# }

# data "hcloud_datacenter" "nbg14_nuremberg" {
#   name = "nbg1-dc3"
# }
# data "hcloud_location" "nbg14_nuremberg" {
#   name = "nbg1"
# }
# # data "hcloud_datacenter" "nbg14_helsinki" {
# #   name = "hel1-dc2"
# # }
# # data "hcloud_location" "nbg14_helsinki" {
# #   name = "hel1"
# # }

# locals {
#   nbg14_patches_zitadel = <<-EOF
#     machine:
#       nodeLabels:
#         app: zitadel
#   EOF
# }

# module "nbg14_talos_cluster" {
#   source = "../modules/talos-cluster"

#   name     = "nbg14"
#   endpoint = "nbg14.dev.248.sh"

#   features = {
#     ip4 = true
#   }

#   patches = {
#     common = [
#       yamlencode({
#         cluster = {
#           extraManifests = [
#             "https://raw.githubusercontent.com/miran248/terraform-talos-modules/refs/tags/v1.0.0/manifests/hcloud-csi.yaml",
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

# module "nbg14_nuremberg_pool_1" {
#   source = "../modules/node-pool"

#   cluster = module.nbg14_talos_cluster

#   zone = 1

#   nodes = {
#     control_planes = [
#       { server_type = "cx22" },
#       { server_type = "cx22" },
#       { server_type = "cx22" },
#     ]
#     workers = [
#       { server_type = "cx22", patches = [local.nbg14_patches_zitadel] },
#       { server_type = "cx22", patches = [local.nbg14_patches_zitadel] },
#       # { server_type = "cx22", patches = [local.nbg14_patches_zitadel] },
#     ]
#   }
# }
# # module "nbg14_helsinki_pool_1" {
# #   source = "../modules/node-pool"

# #   cluster = module.nbg14_talos_cluster

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

# module "nbg14_nuremberg_network_1" {
#   source = "../modules/hcloud-network"

#   datacenter = data.hcloud_datacenter.nbg14_nuremberg
#   location   = data.hcloud_location.nbg14_nuremberg

#   cluster = module.nbg14_talos_cluster
#   pool    = module.nbg14_nuremberg_pool_1
# }
# # module "nbg14_helsinki_network_1" {
# #   source = "../modules/hcloud-network"

# #   datacenter = data.hcloud_datacenter.nbg14_helsinki
# #   location   = data.hcloud_location.nbg14_helsinki

# #   cluster = module.nbg14_talos_cluster
# #   pool    = module.nbg14_helsinki_pool_1
# # }

# module "nbg14_talos_config" {
#   source = "../modules/talos-config"

#   cluster = module.nbg14_talos_cluster
#   networks = [
#     module.nbg14_nuremberg_network_1,
#     # module.nbg14_helsinki_network_1,
#   ]

#   talos_version      = "v1.7.6"
#   kubernetes_version = "v1.30.3"
# }

# module "nbg14_nuremberg_1" {
#   source = "../modules/hcloud-servers"

#   datacenter = data.hcloud_datacenter.nbg14_nuremberg
#   location   = data.hcloud_location.nbg14_nuremberg
#   image_id   = data.hcloud_image.nbg14_v1_7_6_amd64.id

#   cluster = module.nbg14_talos_cluster
#   pool    = module.nbg14_nuremberg_pool_1
#   network = module.nbg14_nuremberg_network_1
#   config  = module.nbg14_talos_config

#   depends_on = [
#     module.nbg14_nuremberg_network_1,
#     module.nbg14_talos_config,
#   ]
# }
# # module "nbg14_helsinki_1" {
# #   source = "../modules/hcloud-servers"

# #   datacenter = data.hcloud_datacenter.nbg14_helsinki
# #   location   = data.hcloud_location.nbg14_helsinki
# #   image_id   = data.hcloud_image.nbg14_v1_7_6_amd64.id

# #   cluster = module.nbg14_talos_cluster
# #   pool    = module.nbg14_helsinki_pool_1
# #   network = module.nbg14_helsinki_network_1
# #   config  = module.nbg14_talos_config

# #   depends_on = [
# #     module.nbg14_helsinki_network_1,
# #     module.nbg14_talos_config,
# #   ]
# # }

# resource "google_dns_record_set" "nbg14_talos_ipv4" {
#   name         = "${module.nbg14_talos_cluster.name}.${data.google_dns_managed_zone.this.dns_name}"
#   managed_zone = data.google_dns_managed_zone.this.name
#   type         = "A"
#   ttl          = 300

#   rrdatas = module.nbg14_talos_config.public_ips4.control_planes

#   depends_on = [
#     module.nbg14_nuremberg_network_1,
#   ]
# }

# module "nbg14_talos_apply" {
#   source = "../modules/talos-apply"

#   cluster = module.nbg14_talos_cluster
#   config  = module.nbg14_talos_config

#   depends_on = [
#     module.nbg14_nuremberg_1,
#     # module.nbg14_helsinki_1,
#   ]
# }

# # outputs
# output "nbg14_talos_config" {
#   value     = module.nbg14_talos_config.talos_config
#   sensitive = true
# }
