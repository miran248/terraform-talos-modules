output "MODULE_NAME" {
  value = "talos-apply"
}

output "kube_config" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "ca_certificate" {
  value     = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
  sensitive = true
}
output "client_certificate" {
  value     = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
  sensitive = true
}
output "client_key" {
  value     = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
  sensitive = true
}
