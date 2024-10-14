# data "talos_cluster_health" "this" {
#   client_configuration = var.config.machine_secrets.client_configuration
#   control_plane_nodes  = var.config.names.control_planes
#   worker_nodes         = var.config.names.workers
#   endpoints            = [var.cluster.endpoint]
#   # skip_kubernetes_checks = true

#   depends_on = [
#     talos_machine_bootstrap.this,
#   ]
# }
