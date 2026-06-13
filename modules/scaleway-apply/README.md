# scaleway-apply
Provisions Scaleway instances with Talos `user_data`, ephemeral local SSD volumes and security groups. Accepts outputs from [scaleway-pool](../scaleway-pool) and [talos-cluster](../talos-cluster). Pass outputs to [talos-apply](../talos-apply).

## inputs

| name | type | description |
|---|---|---|
| `pool` | `object` | `scaleway-pool` module outputs |
| `cluster` | `object` | `talos-cluster` module outputs |
| `inbound_rules` | `list(object)` | Additional inbound security group rules. Fields: `action` (required), `protocol`, `port`, `port_range`, `ip_range`. |

## outputs

| name | description |
|---|---|
| `ips` | node IP addresses - `ips.v6` (map keyed by node name) |

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
