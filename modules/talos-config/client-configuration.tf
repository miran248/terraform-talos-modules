data "talos_client_configuration" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  cluster_name         = var.cluster.name
  endpoints            = [var.cluster.endpoint]
}
