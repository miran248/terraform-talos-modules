# hcloud-apply
Provisions Hetzner Cloud servers with Talos `user_data` and sets up firewalls. Accepts outputs from [hcloud-pool](../hcloud-pool) and [talos-cluster](../talos-cluster). Pass outputs to [talos-apply](../talos-apply).

## inputs

| name | type | description |
|---|---|---|
| `pool` | `object` | `hcloud-pool` module outputs |
| `cluster` | `object` | `talos-cluster` module outputs |
| `rules` | `list(object)` | Additional firewall rules. Fields: `direction` (required), `protocol` (required), `port`, `source_ips`, `destination_ips`, `description`. |

## outputs

| name | description |
|---|---|
| `ips` | node IP addresses - `ips.v6` (map of IPv6 addresses, keyed by node name) |

## example

```hcl
module "nuremberg_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/hcloud-apply?ref=v3.2.3"

  pool    = module.nuremberg_pool
  cluster = module.talos_cluster

  # open http/https for ingress
  rules = [
    { direction = "in", protocol = "tcp", port = "443", source_ips = ["::/0"] },
    { direction = "in", protocol = "tcp", port = "80",  source_ips = ["::/0"] },
  ]
}
```
