# gcp-wif-apply
Fetches OIDC discovery documents (`openid-configuration` and `jwks`) from the running cluster's API server and uploads them to the GCS bucket managed by [gcp-wif](../gcp-wif). Runs after the cluster is bootstrapped.

## inputs

| name | description |
|---|---|
| `identities` | [gcp-wif](../gcp-wif) outputs |
| `cluster` | [talos-cluster](../talos-cluster) outputs |
| `apply` | [talos-apply](../talos-apply) outputs |

## example

```hcl
module "gcp_wif_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/gcp-wif-apply?ref=v4.0.0"

  identities = module.gcp_wif
  cluster    = module.talos_cluster
  apply      = module.talos_apply
}
```
