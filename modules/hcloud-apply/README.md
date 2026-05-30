# hcloud-apply
Provisions Hetzner Cloud servers with Talos `user_data` and sets up firewalls. Accepts outputs from [hcloud-pool](../hcloud-pool) and [talos-cluster](../talos-cluster). Pass outputs to [talos-apply](../talos-apply).

Control plane servers are created before workers to support rolling upgrades. Run with `-parallelism=1` to enforce ordering:

```shell
> terraform apply -parallelism=1
```

## inputs

| name | type | description |
|---|---|---|
| `pool` | `object` | `hcloud-pool` module outputs |
| `cluster` | `object` | `talos-cluster` module outputs |

## outputs

| name | description |
|---|---|
| `ips` | node IP addresses — `ips.v6` (map of IPv6 addresses, keyed by node name) |

## example

```hcl
module "nuremberg_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/hcloud-apply?ref=v3.2.3"

  pool    = module.nuremberg_pool
  cluster = module.talos_cluster
}

locals {
  ips = {
    v6 = module.nuremberg_apply.ips.v6
  }
}


resource "google_dns_record_set" "control_planes" {
  name         = "${module.talos_cluster.name}.${data.google_dns_managed_zone.this.dns_name}"
  managed_zone = data.google_dns_managed_zone.this.name
  type         = "AAAA"
  ttl          = 300
  rrdatas      = values({ for k, v in local.ips.v6 : k => v if module.talos_cluster.nodes[k].kind == "control-plane" })
}
```
