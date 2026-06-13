# scaleway-apply
Provisions Scaleway instances with Talos `user_data`, ephemeral local SSD volumes and security groups. Accepts outputs from [scaleway-pool](../scaleway-pool) and [talos-cluster](../talos-cluster). Pass outputs to [talos-apply](../talos-apply).

## inputs

| name | type | description |
|---|---|---|
| `pool` | [scaleway-pool](../scaleway-pool) outputs | |
| `cluster` | [talos-cluster](../talos-cluster) outputs | |
| `inbound_rules` | `list(inbound_rule)` | additional inbound security group rules |

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
  source = "github.com/miran248/terraform-talos-modules//modules/scaleway-apply?ref=v3.2.3"

  pool    = module.paris_pool
  cluster = module.talos_cluster

  # open http/https for ingress
  inbound_rules = [
    { action = "accept", protocol = "TCP", port = 443 },
    { action = "accept", protocol = "TCP", port = 80 },
  ]
}
```
