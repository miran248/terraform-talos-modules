locals {
  masks4 = {
    xs = { network = 8, machines = 14, services = 14, pods = 13 }
    sm = { network = 8, machines = 13, services = 13, pods = 12 }
    md = { network = 8, machines = 12, services = 12, pods = 11 }
    lg = { network = 8, machines = 11, services = 11, pods = 10 }
    xl = { network = 8, machines = 10, services = 10, pods = 9 }
  }[var.size]
  cidrs4 = {
    xs = {
      network  = "10.0.0.0/8"
      machines = "10.0.0.0/14" # [10.0.0.1   .. 10.3.255.254]
      services = "10.4.0.0/14" # [10.4.0.1   .. 10.7.255.254]
      pods     = "10.8.0.0/13" # [10.8.0.1   .. 10.15.255.254]
      # [10.16.0.0 .. ] is free
    }
    sm = {
      network  = "10.0.0.0/8"
      machines = "10.0.0.0/13"  # [10.0.0.1   .. 10.7.255.254]
      services = "10.8.0.0/13"  # [10.8.0.1   .. 10.15.255.254]
      pods     = "10.16.0.0/12" # [10.16.0.1  .. 10.31.255.254]
      # [10.32.0.0 .. ] is free
    }
    md = {
      network  = "10.0.0.0/8"
      machines = "10.0.0.0/12"  # [10.0.0.1   .. 10.15.255.254]
      services = "10.16.0.0/12" # [10.16.0.1  .. 10.31.255.254]
      pods     = "10.32.0.0/11" # [10.32.0.1  .. 10.63.255.254]
      # [10.64.0.0 .. ] is free
    }
    lg = {
      network  = "10.0.0.0/8"
      machines = "10.0.0.0/11"  # [10.0.0.1   .. 10.31.255.254]
      services = "10.32.0.0/11" # [10.32.0.1  .. 10.63.255.254]
      pods     = "10.64.0.0/10" # [10.64.0.1  .. 10.127.255.254]
      # [10.128.0.0 .. ] is free
    }
    xl = {
      network  = "10.0.0.0/8"
      machines = "10.0.0.0/10"  # [10.0.0.1   .. 10.63.255.254]
      services = "10.64.0.0/10" # [10.64.0.1  .. 10.127.255.254]
      pods     = "10.128.0.0/9" # [10.128.0.1 .. 10.255.255.254]
    }
  }[var.size]
  ips4 = {
    zeros = {
      network  = cidrhost(local.cidrs4.network, 0)  # 10.0.0.0
      machines = cidrhost(local.cidrs4.machines, 0) # 10.0.0.0
      services = cidrhost(local.cidrs4.services, 0) # 10.16.0.0
      pods     = cidrhost(local.cidrs4.pods, 0)     # 10.32.0.0
    }
    gateways = {
      network  = cidrhost(local.cidrs4.network, 1)  # 10.0.0.1
      machines = cidrhost(local.cidrs4.machines, 1) # 10.0.0.1
      services = cidrhost(local.cidrs4.services, 1) # 10.16.0.1
      pods     = cidrhost(local.cidrs4.pods, 1)     # 10.32.0.1
    }
    cluster_dns = cidrhost(local.cidrs4.services, 10) # 10.16.0.10
  }
}
