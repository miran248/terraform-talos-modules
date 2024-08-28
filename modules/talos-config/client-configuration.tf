data "talos_client_configuration" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  cluster_name         = var.cluster_name
  endpoints            = [var.endpoint]
  # nodes                = keys(local.pools.control_planes)
}
