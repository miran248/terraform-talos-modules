output "MODULE_NAME" {
  value = "hcloud-pool"
}

output "prefix" {
  value = var.prefix
}
output "datacenter" {
  value = var.datacenter
}

output "cidr" {
  value = var.cidr
}
output "load_balancer_ip" {
  value = var.load_balancer_ip
}

output "ids" {
  value = local.ids
}

output "control_planes" {
  value = local.control_planes
}
output "workers" {
  value = local.workers
}
output "nodes" {
  value = local.nodes
}
