# scaleway-apply
Provisions Scaleway instances with Talos `user_data`, ephemeral local SSD volumes and security groups. Accepts outputs from [scaleway-pool](../scaleway-pool) and [talos-cluster](../talos-cluster). Pass outputs to [talos-apply](../talos-apply).

## inputs

| name | type | description |
|---|---|---|
| `pool` | [scaleway-pool](../scaleway-pool) outputs | |
| `cluster` | [talos-cluster](../talos-cluster) outputs | |
| `inbound_rules` | `list(inbound_rule)` | additional inbound security group rules |

> **Note:** Scaleway treats rules without `ip_range` as IPv4-only. On IPv6 instances, always set `ip_range = "::/0"` to match all IPv6 traffic; on IPv4 instances use `ip_range = "0.0.0.0/0"`. The module sets built-in rules automatically based on the pool `mode`.

### inbound_rule fields

| name | type | required | description |
|---|---|---|---|
| `action` | `string` | yes | `accept` or `drop` |
| `protocol` | `string` | no | `TCP`, `UDP`, `ICMP`, or `ANY` |
| `port` | `number` | no | single port |
| `port_range` | `string` | no | port range (e.g. `8000-9000`) |
| `ip_range` | `string` | no | source IP range (e.g. `2001:db8::/32`) |

## outputs

| name | description |
|---|---|
| `nodes` | [scaleway-pool](../scaleway-pool) node objects enriched with an `ip` field |

## example

See [scaleway-lb.tf](../../examples/scaleway-lb.tf) for a full example including a Scaleway load balancer frontend for the Talos API and Kubernetes API.

```hcl
module "paris_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/scaleway-apply?ref=v4.2.2" # x-release-please-version

  pool    = module.paris_pool
  cluster = module.talos_cluster

  # open http/https for ingress
  inbound_rules = [
    { action = "accept", protocol = "TCP", port = 443, ip_range = "::/0" },
    { action = "accept", protocol = "TCP", port = 80, ip_range = "::/0" },
  ]
}
```
