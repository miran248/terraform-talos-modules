# hcloud-apply
Provisions Hetzner Cloud servers with Talos `user_data` and sets up firewalls. Accepts outputs from [hcloud-pool](../hcloud-pool) and [talos-cluster](../talos-cluster). Pass outputs to [talos-apply](../talos-apply).

## inputs

| name | type | description |
|---|---|---|
| `pool` | [hcloud-pool](../hcloud-pool) outputs | |
| `cluster` | [talos-cluster](../talos-cluster) outputs | |
| `rules` | `list(rule)` | additional firewall rules |

### rule fields

| name | type | required | description |
|---|---|---|---|
| `direction` | `string` | yes | `in` or `out` |
| `protocol` | `string` | yes | `tcp`, `udp`, `icmp`, `gre`, or `esp` |
| `port` | `string` | no | port or range (e.g. `443`, `8000-9000`) |
| `source_ips` | `list(string)` | no | source IP ranges |
| `destination_ips` | `list(string)` | no | destination IP ranges |
| `description` | `string` | no | |

## outputs

| name | description |
|---|---|
| `nodes` | [hcloud-pool](../hcloud-pool) node objects enriched with an `ip` field |

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
