# data "talos_cluster_health" "this" {
#   client_configuration = var.config.machine_secrets.client_configuration
#   control_plane_nodes  = var.config.private_ips4.control_planes
#   worker_nodes         = var.config.private_ips4.workers
#   endpoints            = [var.cluster.endpoint]
#   # skip_kubernetes_checks = true

#   depends_on = [
#     talos_machine_bootstrap.this,
#   ]
# }
