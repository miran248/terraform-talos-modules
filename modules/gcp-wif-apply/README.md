# gcp-wif-apply
Fetches OIDC discovery documents (`openid-configuration` and `jwks`) from the running cluster's API server and uploads them to the GCS bucket managed by [gcp-wif](../gcp-wif). Runs after the cluster is bootstrapped.

API/load-balancer readiness can lag Talos bootstrap. Discovery requests retry
transient failures with a bounded retry budget. Each cluster uses its own private
TLS files under the root module's `.terraform/gcp-wif-apply/` directory, allowing
multiple local module instances to run concurrently without overwriting credentials.

Run `python3 modules/gcp-wif-apply/tests/run.py` from the repository root to test
concurrent TLS clients and startup retries against local HTTPS servers. It requires
Terraform and OpenSSL; Google resources are mocked.

## inputs

| name | description |
|---|---|
| `identities` | [gcp-wif](../gcp-wif) outputs |
| `cluster` | [talos-cluster](../talos-cluster) outputs |
| `apply` | [talos-apply](../talos-apply) outputs |

## example

```hcl
module "gcp_wif_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/gcp-wif-apply?ref=v4.3.0" # x-release-please-version

  identities = module.gcp_wif
  cluster    = module.talos_cluster
  apply      = module.talos_apply
}
```
