# locals {
#   dev1_ipv4_image_ids = {
#     # hcloud   = data.hcloud_image.v1_14_0_alpha_1_dev_7_amd64.id
#     scaleway = module.scaleway_image_dev["fr-par-1"].ids.image
#   }
# }
#
# module "dev1_ipv4_paris_pool" {
#   source = "../modules/scaleway-pool"
#
#   prefix = "dev1-ipv4-par1"
#   zone   = data.scaleway_availability_zones.paris.zones[0]
#
#   mode = "ipv4"
#
#   control_planes = [
#     { type = "DEV1-M", image = local.dev1_ipv4_image_ids.scaleway },
#     { type = "DEV1-M", image = local.dev1_ipv4_image_ids.scaleway },
#     { type = "DEV1-M", image = local.dev1_ipv4_image_ids.scaleway },
#   ]
#   workers = [
#     { type = "DEV1-M", image = local.dev1_ipv4_image_ids.scaleway },
#   ]
# }
#
# # module "dev1_ipv4_falkenstein_pool" {
# #   source = "../modules/hcloud-pool"
#
# #   prefix   = "dev1-ipv4-fsn"
# #   location = data.hcloud_location.falkenstein.name
#
# #   mode = "ipv4"
#
# #   workers = [
# #     { server_type = "cx23", image = local.dev1_ipv4_image_ids.hcloud },
# #     { server_type = "cx23", image = local.dev1_ipv4_image_ids.hcloud },
# #     { server_type = "cx23", image = local.dev1_ipv4_image_ids.hcloud },
# #   ]
# # }
#
# resource "scaleway_lb_ip" "dev1_ipv4" {
#   zone    = data.scaleway_availability_zones.paris.zones[0]
#   is_ipv6 = false
# }
#
# resource "scaleway_lb" "dev1_ipv4" {
#   ip_ids = [scaleway_lb_ip.dev1_ipv4.id]
#   zone   = data.scaleway_availability_zones.paris.zones[0]
#   name   = "dev1-ipv4"
#   type   = "LB-S"
#
#   lifecycle {
#     ignore_changes = [ip_ids]
#   }
# }
#
# resource "scaleway_lb_backend" "dev1_ipv4_talos" {
#   lb_id            = scaleway_lb.dev1_ipv4.id
#   name             = "dev1-ipv4-talos"
#   forward_protocol = "tcp"
#   forward_port     = 50000
#   proxy_protocol   = "none"
#   server_ips       = [for k, n in module.dev1_ipv4_paris_apply.nodes : n.ip if n.kind == "control-plane"]
# }
#
# resource "scaleway_lb_frontend" "dev1_ipv4_talos" {
#   lb_id        = scaleway_lb.dev1_ipv4.id
#   backend_id   = scaleway_lb_backend.dev1_ipv4_talos.id
#   name         = "dev1-ipv4-talos"
#   inbound_port = 50000
# }
#
# resource "scaleway_lb_backend" "dev1_ipv4_k8s" {
#   lb_id            = scaleway_lb.dev1_ipv4.id
#   name             = "dev1-ipv4-k8s"
#   forward_protocol = "tcp"
#   forward_port     = 6443
#   proxy_protocol   = "none"
#   server_ips       = [for k, n in module.dev1_ipv4_paris_apply.nodes : n.ip if n.kind == "control-plane"]
# }
#
# resource "scaleway_lb_frontend" "dev1_ipv4_k8s" {
#   lb_id        = scaleway_lb.dev1_ipv4.id
#   backend_id   = scaleway_lb_backend.dev1_ipv4_k8s.id
#   name         = "dev1-ipv4-k8s"
#   inbound_port = 6443
# }
#
# module "dev1_ipv4_talos_cluster" {
#   source = "../modules/talos-cluster"
#
#   name               = "dev1-ipv4"
#   endpoint           = scaleway_lb_ip.dev1_ipv4.ip_address
#   talos_version      = "v1.14.0-alpha.4"
#   kubernetes_version = "v1.36.1"
#
#   pools = [
#     module.dev1_ipv4_paris_pool,
#     # module.dev1_ipv4_falkenstein_pool,
#   ]
#
#   patches = {
#     common = [
#       <<-EOF
#         apiVersion: v1alpha1
#         kind: TimeSyncConfig
#         ptp:
#           devices:
#             - /dev/ptp0
#       EOF
#       ,
#     ]
#     control_planes = flatten([
#       module.gcp_wif.patches.control_planes,
#       <<-EOF
#         cluster:
#           allowSchedulingOnControlPlanes: true
#       EOF
#     ])
#   }
# }
#
# module "dev1_ipv4_paris_apply" {
#   source = "../modules/scaleway-apply"
#
#   pool    = module.dev1_ipv4_paris_pool
#   cluster = module.dev1_ipv4_talos_cluster
#
#   inbound_rules = [
#     { action = "accept", protocol = "TCP", port = 443, ip_range = "0.0.0.0/0" },
#     { action = "accept", protocol = "TCP", port = 80, ip_range = "0.0.0.0/0" },
#   ]
# }
#
# # module "dev1_ipv4_falkenstein_apply" {
# #   source = "../modules/hcloud-apply"
#
# #   pool    = module.dev1_ipv4_falkenstein_pool
# #   cluster = module.dev1_ipv4_talos_cluster
# # }
#
# module "dev1_ipv4_talos_apply" {
#   source = "../modules/talos-apply"
#
#   cluster = module.dev1_ipv4_talos_cluster
#   # applies         = [module.dev1_ipv4_paris_apply, module.dev1_ipv4_falkenstein_apply]
#   applies         = [module.dev1_ipv4_paris_apply]
#   installer_image = "ghcr.io/miran248/talos-installer:v1.14.0-alpha.1-dev.7"
# }
#
# module "dev1_ipv4_gcp_wif_apply" {
#   source = "../modules/gcp-wif-apply"
#
#   identities = module.gcp_wif
#   cluster    = module.dev1_ipv4_talos_cluster
#   apply      = module.dev1_ipv4_talos_apply
# }
#
# # outputs
# output "talos_config_ipv4" {
#   value     = module.dev1_ipv4_talos_cluster.talos_config
#   sensitive = true
# }
# output "kube_config_ipv4" {
#   value     = module.dev1_ipv4_talos_apply.kube_config
#   sensitive = true
# }
