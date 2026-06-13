# hcloud-pool
Allocates Hetzner Cloud resources for a node pool: one IPv6 /64 primary IP per node and a placement group. Does not provision servers - pass outputs to [hcloud-apply](../hcloud-apply) and [talos-cluster](../talos-cluster).

## inputs

| name | type | required | description |
|---|---|---|---|
| `prefix` | `string` | yes | resource name prefix, must be unique across pools |
| `location` | `string` | yes | Hetzner Cloud location (e.g. `nbg1`, `hel1`, `fsn1`) |
| `control_planes` | `list(node)` | no | control plane node definitions |
| `workers` | `list(node)` | no | worker node definitions |
| `patches` | `patches` | no | pool-wide config patches |

### node fields

| name | type | required | description |
|---|---|---|---|
| `server_type` | `string` | yes | Hetzner server type (e.g. `cx22`) |
| `image` | `number` | yes | Hetzner image ID (use `hcloud_image` data source) |
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
| `location` | Hetzner location |
| `nodes` | map of fully resolved node objects, keyed by node name |
| `ids` | resource IDs (`group`, `ips.v6`) |

## example

```hcl
data "hcloud_image" "talos" {
  with_selector = "name=talos,version=v1.14.0,arch=amd64"
}

module "nuremberg_pool" {
  source = "github.com/miran248/terraform-talos-modules//modules/hcloud-pool?ref=v3.2.3"

  prefix   = "nbg"
  location = "nbg1"

  control_planes = [
    { server_type = "cx22", image = data.hcloud_image.talos.id },
    { server_type = "cx22", image = data.hcloud_image.talos.id },
    { server_type = "cx22", image = data.hcloud_image.talos.id },
  ]
  workers = [
    { server_type = "cx22", image = data.hcloud_image.talos.id },
  ]
}
```
