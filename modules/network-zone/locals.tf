locals {
  max_control_planes = 9
  max_workers        = 229

  cidrs4 = {
    machines = "10.${var.cloud}.${var.region}${var.zone}.0/24"
  }

  ips4 = {
    load_balancer  = cidrhost(local.cidrs4.machines, 5)                                                   # 10.1.11.5
    router         = cidrhost(local.cidrs4.machines, 10)                                                  # 10.1.11.10
    router_client  = cidrhost(local.cidrs4.machines, 9)                                                   # 10.1.11.9
    control_planes = [for i in range(local.max_control_planes) : cidrhost(local.cidrs4.machines, 11 + i)] # 10.1.11.11 ..
    workers        = [for i in range(local.max_workers) : cidrhost(local.cidrs4.machines, 21 + i)]        # 10.1.11.21 ..
  }
}
