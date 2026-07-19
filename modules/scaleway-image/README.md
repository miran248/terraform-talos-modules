# scaleway-image
Registers a Talos qcow2 image stored in a Scaleway Object Storage bucket as a bootable Scaleway instance image. Run once per zone before creating pools.

## inputs

| name | type | description |
|---|---|---|
| `zone` | `string` | Scaleway zone (e.g. `fr-par-1`) |
| `bucket` | `string` | Scaleway bucket name containing the qcow2 file |
| `object` | `string` | path to the qcow2 file within the bucket |
| `name` | `string` | name for the resulting snapshot and image |

## outputs

| name | description |
|---|---|
| `zone` | Scaleway zone |
| `ids` | resource IDs: `bucket`, `object`, `snapshot`, `image` |

## example

```hcl
module "scaleway_image" {
  for_each = toset(["fr-par-1", "fr-par-2"])
  source   = "github.com/miran248/terraform-talos-modules//modules/scaleway-image?ref=v4.2.0"

  zone   = each.key
  bucket = "my-talos-images"
  object = "talos-v1.14.0-amd64.qcow2"
  name   = "talos-v1.14.0-amd64"
}

module "paris_pool" {
  source = "github.com/miran248/terraform-talos-modules//modules/scaleway-pool?ref=v4.2.0"

  prefix = "par1"
  zone   = "fr-par-1"

  control_planes = [
    { type = "DEV1-M", image = module.scaleway_image["fr-par-1"].ids.image },
  ]
}
```
