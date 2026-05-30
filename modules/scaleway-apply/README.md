# scaleway-apply
Provisions Scaleway instances with Talos `user_data`, ephemeral local SSD volumes and security groups. Accepts outputs from [scaleway-pool](../scaleway-pool) and [talos-cluster](../talos-cluster). Pass outputs to [talos-apply](../talos-apply).

Control plane servers are created before workers to support rolling upgrades. Run with `-parallelism=1` to enforce ordering:

```shell
> terraform apply -parallelism=1
```

## inputs

| name | type | description |
|---|---|---|
| `pool` | `object` | `scaleway-pool` module outputs |
| `cluster` | `object` | `talos-cluster` module outputs |

## outputs

| name | description |
|---|---|
| `ips` | node IP addresses — `ips.v6` and `ips.v4` (maps keyed by node name) |

## example

```hcl
module "paris_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/scaleway-apply?ref=v3.2.3"

  pool    = module.paris_pool
  cluster = module.talos_cluster
}

locals {
  ips = {
    v6 = module.paris_apply.ips.v6
    v4 = module.paris_apply.ips.v4
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
