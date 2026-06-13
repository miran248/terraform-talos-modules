locals {
  ips = {
    v6 = { for key, _ in var.pool.nodes :
      key => [for pip in scaleway_instance_server.this[key].public_ips :
        pip.address if pip.id == var.pool.ids.ips.v6[key]
      ][0]
    }
  }
}
