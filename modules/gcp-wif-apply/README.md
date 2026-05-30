# gcp-wif-apply
Fetches OIDC discovery documents (`openid-configuration` and `jwks`) from the running cluster's API server and uploads them to the GCS bucket managed by [gcp-wif](../gcp-wif). Runs after the cluster is bootstrapped.

## inputs

| name | type | description |
|---|---|---|
| `identities` | `object` | `gcp-wif` module outputs |
| `cluster` | `object` | `talos-cluster` module outputs |
| `apply` | `object` | `talos-apply` module outputs |

## example

```hcl
module "gcp_wif_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/gcp-wif-apply?ref=v3.2.3"

  identities = module.gcp_wif
  cluster    = module.talos_cluster
  apply      = module.talos_apply
}
```
