# scaleway-pool
Allocates Scaleway resources for a node pool: one routed IP per node (IPv6 or IPv4) and a placement group. Does not provision servers - pass outputs to [scaleway-apply](../scaleway-apply) and [talos-cluster](../talos-cluster).

## inputs

| name | type | required | description |
|---|---|---|---|
| `prefix` | `string` | yes | resource name prefix, must be unique across pools |
| `zone` | `string` | yes | Scaleway zone (e.g. `fr-par-1`) |
| `mode` | `string` | no | IP family: `ipv6` (default) or `ipv4` |
| `control_planes` | `list(node)` | no | control plane node definitions |
| `workers` | `list(node)` | no | worker node definitions |
| `patches` | `patches` | no | pool-wide config patches |

### node fields

| name | type | required | description |
|---|---|---|---|
| `type` | `string` | yes | Scaleway instance type (e.g. `DEV1-M`) |
| `image` | `string` | yes | Scaleway image ID (use [scaleway-image](../scaleway-image)) |
| `aliases` | `list(string)` | no | additional DNS aliases for this node |
| `patches` | `list(string)` | no | node-specific config patches |
| `removed` | `bool` | no | set `true` to drain and remove the node |

### patches fields

| name | type | description |
|---|---|---|
| `common` | `list(string)` | applied to all nodes in this pool |
| `control_planes` | `list(string)` | applied to control plane nodes only |
| `workers` | `list(string)` | applied to worker nodes only |

## outputs

| name | description |
|---|---|
| `prefix` | pool prefix |
| `zone` | Scaleway zone |
| `nodes` | map of fully resolved node objects, keyed by node name |
| `mode` | IP family (`ipv6` or `ipv4`) |
| `ids` | resource IDs (`group`, `ips`) |

## example

```hcl
module "paris_pool" {
  source = "github.com/miran248/terraform-talos-modules//modules/scaleway-pool?ref=v4.2.2"

  prefix = "par1"
  zone   = "fr-par-1"

  control_planes = [
    { type = "DEV1-M", image = module.scaleway_image["fr-par-1"].ids.image },
    { type = "DEV1-M", image = module.scaleway_image["fr-par-1"].ids.image },
    { type = "DEV1-M", image = module.scaleway_image["fr-par-1"].ids.image },
  ]
  workers = [
    { type = "DEV1-M", image = module.scaleway_image["fr-par-1"].ids.image },
  ]
}
```
